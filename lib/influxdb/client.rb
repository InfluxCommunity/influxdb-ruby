require 'uri'
require 'cgi'
require 'net/http'
require 'net/https'
require 'json'

module InfluxDB
  class Client
    attr_accessor :hosts,
                  :port,
                  :username,
                  :password,
                  :database,
                  :time_precision,
                  :use_ssl,
                  :stopped,
                  :auth_method

    attr_accessor :queue, :worker, :udp_client

    include InfluxDB::Logging

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
      @hosts = Array(opts[:hosts] || opts[:host] || ["localhost"])
      @port = opts[:port] || 8086
      @username = opts[:username] || "root"
      @password = opts[:password] || "root"
      @auth_method = %w{params basic_auth}.include?(opts[:auth_method]) ? opts[:auth_method] : "params"
      @use_ssl = opts[:use_ssl] || false
      @time_precision = opts[:time_precision] || "s"
      @initial_delay = opts[:initial_delay] || 0.01
      @max_delay = opts[:max_delay] || 30
      @open_timeout = opts[:write_timeout] || 5
      @read_timeout = opts[:read_timeout] || 300
      @async = opts[:async] || false
      @retry = opts.fetch(:retry, nil)
      @retry = case @retry
      when Integer
        @retry
      when true, nil
        -1
      when false
        0
      end

      @worker = InfluxDB::Worker.new(self) if @async
      self.udp_client = opts[:udp] ? InfluxDB::UDPClient.new(opts[:udp][:host], opts[:udp][:port]) : nil

      at_exit { stop! }
    end

    ## allow options, e.g. influxdb.create_database('foo', replicationFactor: 3)
    def create_database(name, options = {})
      url = full_url("/db")
      options[:name] = name
      data = JSON.generate(options)
      post(url, data)
    end

    def delete_database(name)
      delete full_url("/db/#{name}")
    end

    def get_database_list
      get full_url("/db")
    end

    def create_cluster_admin(username, password)
      url = full_url("/cluster_admins")
      data = JSON.generate({:name => username, :password => password})
      post(url, data)
    end

    def update_cluster_admin(username, password)
      url = full_url("/cluster_admins/#{username}")
      data = JSON.generate({:password => password})
      post(url, data)
    end

    def delete_cluster_admin(username)
      delete full_url("/cluster_admins/#{username}")
    end

    def get_cluster_admin_list
      get full_url("/cluster_admins")
    end

    def create_database_user(database, username, password)
      url = full_url("/db/#{database}/users")
      data = JSON.generate({:name => username, :password => password})
      post(url, data)
    end

    def update_database_user(database, username, options = {})
      url = full_url("/db/#{database}/users/#{username}")
      data = JSON.generate(options)
      post(url, data)
    end

    def delete_database_user(database, username)
      delete full_url("/db/#{database}/users/#{username}")
    end

    def get_database_user_list(database)
      get full_url("/db/#{database}/users")
    end

    def get_database_user_info(database, username)
      get full_url("/db/#{database}/users/#{username}")
    end

    def alter_database_privilege(database, username, admin=true)
      update_database_user(database, username, :admin => admin)
    end

    def continuous_queries(database)
      get full_url("/db/#{database}/continuous_queries")
    end

    def get_shard_list()
      get full_url("/cluster/shards")
    end

    def delete_shard(shard_id, server_ids)
      data = JSON.generate({"serverIds" => server_ids})
      delete full_url("/cluster/shards/#{shard_id}"), data
    end

    def write_point(name, data, async=@async, time_precision=@time_precision)
      data = data.is_a?(Array) ? data : [data]
      columns = data.reduce(:merge).keys.sort {|a,b| a.to_s <=> b.to_s}
      payload = {:name => name, :points => [], :columns => columns}

      data.each do |point|
        payload[:points] << columns.inject([]) do |array, column|
          array << InfluxDB::PointValue.new(point[column]).dump
        end
      end

      if async
        worker.push(payload)
      elsif udp_client
        udp_client.send([payload])
      else
        _write([payload], time_precision)
      end
    end

    def _write(payload, time_precision=@time_precision)
      url = full_url("/db/#{@database}/series", :time_precision => time_precision)
      data = JSON.generate(payload)
      post(url, data)
    end

    def query(query, time_precision=@time_precision)
      url = full_url("/db/#{@database}/series", :q => query, :time_precision => time_precision)
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

    def delete_series(series)
      delete full_url("/db/#{@database}/series/#{series}")
    end

    def stop!
      @stopped = true
    end

    def stopped?
      @stopped
    end

    private

    def full_url(path, params={})
      unless basic_auth?
        params[:u] = @username
        params[:p] = @password
      end

      query = params.map { |k, v| [CGI.escape(k.to_s), "=", CGI.escape(v.to_s)].join }.join("&")

      URI::Generic.build(:path => path, :query => query).to_s
    end

    def basic_auth?
      @auth_method == 'basic_auth'
    end

    def get(url)
      connect_with_retry do |http|
        request = Net::HTTP::Get.new(url)
        request.basic_auth @username, @password if basic_auth?
        response = http.request(request)
        if response.kind_of? Net::HTTPSuccess
          return JSON.parse(response.body)
        elsif response.kind_of? Net::HTTPUnauthorized
          raise InfluxDB::AuthenticationError.new response.body
        else
          raise InfluxDB::Error.new response.body
        end
      end
    end

    def post(url, data)
      headers = {"Content-Type" => "application/json"}
      connect_with_retry do |http|
        request = Net::HTTP::Post.new(url, headers)
        request.basic_auth @username, @password if basic_auth?
        response = http.request(request, data)
        if response.kind_of? Net::HTTPSuccess
          return response
        elsif response.kind_of? Net::HTTPUnauthorized
          raise InfluxDB::AuthenticationError.new response.body
        else
          raise InfluxDB::Error.new response.body
        end
      end
    end

    def delete(url, data = nil)
      headers = {"Content-Type" => "application/json"}
      connect_with_retry do |http|
        request = Net::HTTP::Delete.new(url, headers)
        request.basic_auth @username, @password if basic_auth?
        response = http.request(request, data)
        if response.kind_of? Net::HTTPSuccess
          return response
        elsif response.kind_of? Net::HTTPUnauthorized
          raise InfluxDB::AuthenticationError.new response.body
        else
          raise InfluxDB::Error.new response.body
        end
      end
    end

    def connect_with_retry(&block)
      hosts = @hosts.dup
      delay = @initial_delay
      retry_count = 0

      begin
        hosts.push(host = hosts.shift)
        http = Net::HTTP.new(host, @port)
        http.open_timeout = @open_timeout
        http.read_timeout = @read_timeout
        http.use_ssl = @use_ssl
        block.call(http)

      rescue Timeout::Error, *InfluxDB::NET_HTTP_EXCEPTIONS => e
        retry_count += 1
        if (@retry == -1 or retry_count <= @retry) and !stopped?
          log :error, "Failed to contact host #{host}: #{e.inspect} - retrying in #{delay}s."
          log :info, "Queue size is #{@queue.length}." unless @queue.nil?
          sleep delay
          delay = [@max_delay, delay * 2].min
          retry
        else
          raise e, "Tried #{retry_count-1} times to reconnect but failed."
        end
      ensure
        http.finish if http.started?
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

    WORKER_MUTEX = Mutex.new
    def worker
      return @worker if @worker
      WORKER_MUTEX.synchronize do
        #this return is necessary because the previous mutex holder might have already assigned the @worker
        return @worker if @worker
        @worker = InfluxDB::Worker.new(self)
      end
    end
  end
end
