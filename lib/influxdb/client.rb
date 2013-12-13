require 'uri'
require 'net/http'
require 'json'

module InfluxDB
  class Client
    attr_accessor :host, :port, :username, :password, :database
    attr_accessor :queue

    include InfluxDB::Logger
    include InfluxDB::Worker

    # Initializes a new Influxdb client
    #
    # === Examples:
    #
    #     Influxdb.new                               # connect to localhost using root/root
    #                                                # as the credentials and doesn't connect to a db
    #
    #     Influxdb.new 'db'                          # connect to localhost using root/root
    #                                                # as the credentials and 'db' as the db name
    #
    #     Influxdb.new :username => 'username'       # override username, other defaults remain unchanged
    #
    #     Influxdb.new 'db', :username => 'username' # override username, use 'db' as the db name
    #
    # === Valid options in hash
    #
    # +:hostname+:: the hostname to connect to
    # +:port+:: the port to connect to
    # +:username+:: the username to use when executing commands
    # +:password+:: the password associated with the username
    # +:async+:: write points asynchronously
    def initialize *args
      @database = args.first if args.first.is_a? String
      opts = args.last.is_a?(Hash) ? args.last : {}
      @host = opts[:host] || "localhost"
      @port = opts[:port] || 8086
      @username = opts[:username] || "root"
      @password = opts[:password] || "root"
      @http = Net::HTTP.new(@host, @port)
      @async = opts[:async] || false
      if async?
        @queue = InfluxDB::MaxQueue.new
        spawn_threads!
      end
    end

    def async?
      @async == true
    end

    def create_database(name)
      url = full_url("db")
      data = JSON.generate({:name => name})

      headers = {"Content-Type" => "application/json"}
      response = @http.request(Net::HTTP::Post.new(url, headers), data)
    end

    def delete_database(name)
      url = full_url("db/#{name}")

      response = @http.request(Net::HTTP::Delete.new(url))
    end

    def get_database_list
      url = full_url("db")

      response = @http.request(Net::HTTP::Get.new(url))
      JSON.parse(response.body)
    end

    def create_cluster_admin(username, password)
      url = full_url("cluster_admins")
      data = JSON.generate({:name => username, :password => password})

      headers = {"Content-Type" => "application/json"}
      response = @http.request(Net::HTTP::Post.new(url, headers), data)
    end

    def update_cluster_admin(username, password)
      url = full_url("cluster_admins/#{username}")
      data = JSON.generate({:password => password})

      headers = {"Content-Type" => "application/json"}
      response = @http.request(Net::HTTP::Post.new(url, headers), data)
    end

    def delete_cluster_admin(username)
      url = full_url("cluster_admins/#{username}")

      response = @http.request(Net::HTTP::Delete.new(url))
    end

    def get_cluster_admin_list
      url = full_url("cluster_admins")

      response = @http.request(Net::HTTP::Get.new(url))
      JSON.parse(response.body)
    end

    def create_database_user(database, username, password)
      url = full_url("db/#{database}/users")
      data = JSON.generate({:name => username, :password => password})

      headers = {"Content-Type" => "application/json"}
      response = @http.request(Net::HTTP::Post.new(url, headers), data)
    end

    def update_database_user(database, username, options = {})
      url = full_url("db/#{database}/users/#{username}")
      data = JSON.generate(options)

      headers = {"Content-Type" => "application/json"}
      @http.request(Net::HTTP::Post.new(url, headers), data)
    end

    def delete_database_user(database, username)
      url = full_url("db/#{database}/users/#{username}")

      @http.request(Net::HTTP::Delete.new(url))
    end

    def get_database_user_list(database)
      url = full_url("db/#{database}/users")

      response = @http.request(Net::HTTP::Get.new(url))
      JSON.parse(response.body)
    end

    def alter_database_privilege(database, username, admin=true)
      update_database_user(database, username, :admin => admin)
    end

    def write_point(name, data)
      data = data.is_a?(Array) ? data : [data]
      columns = data.reduce(:merge).keys.sort {|a,b| a.to_s <=> b.to_s}
      payload = {:name => name, :points => [], :columns => columns}

      data.each do |p|
        point = []
        columns.each { |c| point << p[c] }
        payload[:points].push point
      end

      async? ? @queue.push(payload) : _write([payload])
    end

    def _write(payload)
      url = full_url("db/#{@database}/series")
      data = JSON.generate(payload)

      headers = {"Content-Type" => "application/json"}
      response = @http.request(Net::HTTP::Post.new(url, headers), data)
      raise "Write failed with '#{response.message}'" unless (200...300).include?(response.code.to_i)
      response
    end

    def query(query)
      url = full_url("db/#{@database}/series", "q=#{query}")
      url = URI.encode url
      response = @http.request(Net::HTTP::Get.new(url))
      series = JSON.parse(response.body)

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

    def denormalize_series series
      columns = series['columns']
      series['points'].map { |point| Hash[columns.zip(point)]}
    end
  end
end
