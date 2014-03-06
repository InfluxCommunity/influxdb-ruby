require 'uri'
require 'net/http'
require 'net/https'
require 'json'

module InfluxDB
  class Client
    attr_accessor :host, :port, :username, :password, :database, :time_precision
    attr_accessor :queue, :worker

    include InfluxDB::Logger

    # Initializes a new InfluxDB client
    #
    # === Examples:
    #
    #     InfluxDB::Client.new                               # connect to localhost using root/root
    #                                                        # as the credentials and doesn't connect to a db
    #
    #     InfluxDB::Client.new 'db'                          # connect to localhost using root/root
    #                                                        # as the credentials and 'db' as the db name
    #
    #     InfluxDB::Client.new :username => 'username'       # override username, other defaults remain unchanged
    #
    #     Influxdb::Client.new 'db', :username => 'username' # override username, use 'db' as the db name
    #
    # === Valid options in hash
    #
    # +:host+:: the hostname to connect to
    # +:port+:: the port to connect to
    # +:username+:: the username to use when executing commands
    # +:password+:: the password associated with the username
    # +:use_ssl+:: use ssl to connect
    def initialize *args
      @database = args.first if args.first.is_a? String
      opts = args.last.is_a?(Hash) ? args.last : {}
      @host = opts[:host] || "localhost"
      @port = opts[:port] || 8086
      @username = opts[:username] || "root"
      @password = opts[:password] || "root"
      @http = Net::HTTP.new(@host, @port)
      @http.use_ssl = opts[:use_ssl]
      @time_precision = opts[:time_precision] || "m"
    end

    ## allow options, e.g. influxdb.create_database('foo', replicationFactor: 3)
    def create_database(name, options = {})
      url = full_url("db")
      options[:name] = name
      data = JSON.generate(options)
      post(url, data)
    end

    def delete_database(name)
      delete full_url("db/#{name}")
    end

    def get_database_list
      get full_url("db")
    end

    def create_cluster_admin(username, password)
      url = full_url("cluster_admins")
      data = JSON.generate({:name => username, :password => password})
      post(url, data)
    end

    def update_cluster_admin(username, password)
      url = full_url("cluster_admins/#{username}")
      data = JSON.generate({:password => password})
      post(url, data)
    end

    def delete_cluster_admin(username)
      delete full_url("cluster_admins/#{username}")
    end

    def get_cluster_admin_list
      get full_url("cluster_admins")
    end

    def create_database_user(database, username, password)
      url = full_url("db/#{database}/users")
      data = JSON.generate({:name => username, :password => password})
      post(url, data)
    end

    def update_database_user(database, username, options = {})
      url = full_url("db/#{database}/users/#{username}")
      data = JSON.generate(options)
      post(url, data)
    end

    def delete_database_user(database, username)
      delete full_url("db/#{database}/users/#{username}")
    end

    def get_database_user_list(database)
      get full_url("db/#{database}/users")
    end

    def get_database_user_info(database, username)
      get full_url("db/#{database}/users/#{username}")
    end

    def alter_database_privilege(database, username, admin=true)
      update_database_user(database, username, :admin => admin)
    end

    def write_point(name, data, async=false, time_precision=@time_precision)
      data = data.is_a?(Array) ? data : [data]
      columns = data.reduce(:merge).keys.sort {|a,b| a.to_s <=> b.to_s}
      payload = {:name => name, :points => [], :columns => columns}

      data.each do |point|
        payload[:points] << columns.inject([]) do |array, column|
          array << InfluxDB::PointValue.new(point[column]).dump
        end
      end

      if async
        @worker = InfluxDB::Worker.new if @worker.nil?
        @worker.queue.push(payload)
      else
        _write([payload], time_precision)
      end
    end

    def _write(payload, time_precision=nil)
      url = full_url("db/#{@database}/series", "time_precision=#{time_precision}")
      data = JSON.generate(payload)

      headers = {"Content-Type" => "application/json"}
      response = @http.request(Net::HTTP::Post.new(url, headers), data)
      raise "Write failed with '#{response.message}'" unless (200...300).include?(response.code.to_i)
      response
    end

    def query(query)
      url = URI.encode full_url("db/#{@database}/series", "q=#{query}")
      series = get(url)

      if block_given?
        series.each { |s| yield s['name'], denormalize_series(s) }
      else
        series.reduce({}) do |col, s|
          name                  = s['name']
          denormalized_series   = denormalize_series s
          col[name]             = denormalized_series
          col
        end
      end
    end

    private
    def full_url(path, params=nil)
      "".tap do |url|
        url << "/#{path}?u=#{@username}&p=#{@password}"
        url << "&#{params}" unless params.nil?
      end
    end

    def get(url)
      response = @http.request(Net::HTTP::Get.new(url))
      if response.kind_of? Net::HTTPSuccess
        return JSON.parse(response.body)
      elsif response.kind_of? Net::HTTPUnauthorized
        raise InfluxDB::AuthenticationError.new response.body
      else
        raise InfluxDB::Error.new response.body
      end
    end

    def post(url, data)
      headers = {"Content-Type" => "application/json"}
      response = @http.request(Net::HTTP::Post.new(url, headers), data)
      if response.kind_of? Net::HTTPSuccess
        return response
      elsif response.kind_of? Net::HTTPUnauthorized
        raise InfluxDB::AuthenticationError.new response.body
      else
        raise InfluxDB::Error.new response.body
      end
    end

    def delete(url)
      response = @http.request(Net::HTTP::Delete.new(url))
      if response.kind_of? Net::HTTPSuccess
        return response
      elsif response.kind_of? Net::HTTPUnauthorized
        raise InfluxDB::AuthenticationError.new response.body
      else
        raise InfluxDB::Error.new response.body
      end
    end

    def denormalize_series series
      columns = series['columns']

      h = Hash.new(-1)
      columns = columns.map {|v| h[v] += 1; h[v] > 0 ? "#{v}~#{h[v]}" : v }

      series['points'].map do |point|
        decoded_point = point.map do |value|
          InfluxDB::PointValue.new(value).load
        end
        Hash[columns.zip(decoded_point)]
      end
    end
  end
end
