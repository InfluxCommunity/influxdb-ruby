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
    #     Influxdb::Client.new 'db', :path => '/prefix'      # use the specified path prefix when building the
    #                                                        # url e.g.: /prefix/db/dbname...
    #
    # === Valid options in hash
    #
    # +:host+:: the hostname to connect to
    # +:port+:: the port to connect to
    # +:username+:: the username to use when executing commands
    # +:password+:: the password associated with the username
    # +:use_ssl+:: use ssl to connect
    # +:verify_ssl+:: verify ssl server certificate
    def initialize *args
      @database = args.first if args.first.is_a? String
      opts = args.last.is_a?(Hash) ? args.last : {}
      @hosts = Array(opts[:hosts] || opts[:host] || ["localhost"])
      @port = opts[:port] || 8086
      @path = opts[:path] || ""
      @username = opts[:username] || "root"
      @password = opts[:password] || "root"
      @auth_method = %w{params basic_auth}.include?(opts[:auth_method]) ? opts[:auth_method] : "params"
      @verify_mode = opts[:verify_mode] || OpenSSL::SSL::VERIFY_PEER
      @cert_key = opts[:cert_key] || nil
      @cert_path = opts[:cert_path] || nil
      @use_ssl = opts[:use_ssl] || false
      @verify_ssl = opts.fetch(:verify_ssl, true)
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

      at_exit { stop! } if @retry > 0
    end

    def ping
      get "/ping"
    end

    ## allow options, e.g. influxdb.create_database('foo', replicationFactor: 3)
    def create_database(name, options = {})
      url = full_url("/cluster/database_configs/#{name}")
      data = JSON.generate(options)
      post(url, data)
    end

    def delete_database(name)
      delete full_url("/db/#{name}")
    end

    def get_database_list
      get full_url("/db")
    end

    def authenticate_cluster_admin
      get(full_url('/cluster_admins/authenticate'), true)
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

    def authenticate_database_user(database)
      get(full_url("/db/#{database}/authenticate"), true)
    end

    def create_database_user(database, username, password, options={})
      url = full_url("/db/#{database}/users")
      data = JSON.generate({:name => username, :password => password}.merge(options))
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

    # NOTE: Only cluster admin can call this
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

    # EXAMPLE:
    #
    # db.create_continuous_query(
    #   "select mean(sys) as sys, mean(usr) as usr from cpu group by time(15m)",
    #   "cpu.15m",
    # )
    #
    # NOTE: Only cluster admin can call this
    def create_continuous_query(query, name)
      query("#{query} into #{name}")
    end

    # NOTE: Only cluster admin can call this
    def get_continuous_query_list
      query("list continuous queries")
    end
    
    # NOTE: Only cluster admin can call this
    def delete_continuous_query(id)
      query("drop continuous query #{id}")
    end

    def get_shard_space_list
      get full_url("/cluster/shard_spaces")
    end

    def get_shard_space(database_name, shard_space_name)
      get_shard_space_list.find do |shard_space|
        shard_space["database"] == database_name &&
          shard_space["name"] == shard_space_name
      end
    end

    def create_shard_space(database_name, options = {})
      url  = full_url("/cluster/shard_spaces/#{database_name}")
      data = JSON.generate(default_shard_space_options.merge(options))

      post(url, data)
    end

    def delete_shard_space(database_name, shard_space_name)
      delete full_url("/cluster/shard_spaces/#{database_name}/#{shard_space_name}")
    end

    ## Get the shard space first, so the user doesn't have to specify the existing options
    def update_shard_space(database_name, shard_space_name, options)
      shard_space_options = get_shard_space(database_name, shard_space_name)
      shard_space_options.delete("database")

      url  = full_url("/cluster/shard_spaces/#{database_name}/#{shard_space_name}")
      data = JSON.generate(shard_space_options.merge(options))

      post(url, data)
    end

    def default_shard_space_options
      {
        "name"              => "default",
        "regEx"             => "/.*/",
        "retentionPolicy"   => "inf",
        "shardDuration"     => "7d",
        "replicationFactor" => 1,
        "split"             => 1
      }
    end

    def configure_database(database_name, options = {})
      url  = full_url("/cluster/database_configs/#{database_name}")
      data = JSON.generate(default_database_configuration.merge(options))

      post(url, data)
    end

    def default_database_configuration
      {:spaces => [default_shard_space_options]}
    end

    def write_point(name, data, async=@async, time_precision=@time_precision)
      write_points([{:name => name, :data => data}], async, time_precision)
    end

    # Example:
    # db.write_points(
    #     [
    #         {
    #             name: 'first_name',
    #             data: {
    #                 value: 'val1'
    #             }
    #         },
    #         {
    #             name: 'first_name',
    #             data: {
    #                 value: 'val1'
    #             }
    #         }
    #     ]
    # )
    def write_points(name_data_hashes_array, async=@async, time_precision=@time_precision)

      payloads = []
      name_data_hashes_array.each do |attrs|
        payloads << generate_payload(attrs[:name], attrs[:data])
      end

      if async
        worker.push(payloads)
      elsif udp_client
        udp_client.send(payloads)
      else
        _write(payloads, time_precision)
      end
    end

    def generate_payload(name, data)
      data = data.is_a?(Array) ? data : [data]
      columns = data.reduce(:merge).keys.sort {|a,b| a.to_s <=> b.to_s}
      payload = {:name => name, :points => [], :columns => columns}

      data.each do |point|
        payload[:points] << columns.inject([]) do |array, column|
          array << InfluxDB::PointValue.new(point[column]).dump
        end
      end

      payload
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

      URI::Generic.build(:path => "#{@path}#{path}", :query => query).to_s
    end

    def basic_auth?
      @auth_method == 'basic_auth'
    end

    def get(url, return_response = false)
      connect_with_retry do |http|
        request = Net::HTTP::Get.new(url)
        request.basic_auth @username, @password if basic_auth?
        response = http.request(request)
        if response.kind_of? Net::HTTPSuccess
          if return_response
            return response
          else
            return JSON.parse(response.body)
          end
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

    def certificate_path
      OpenSSL::X509::Certificate.new(File.read(@cert_path)) unless @cert_path.nil?
    end

    def certificate_key
      OpenSSL::PKey::RSA.new(File.read(@cert_key)) unless @cert_key.nil?
    end

    def connect_with_retry(&block)
      hosts = @hosts.dup
      delay = @initial_delay
      retry_count = 0

      begin
        hosts.push(host = hosts.shift)
        http = Net::HTTP.new(host, @port)
        http.cert = certificate_path
        http.key = certificate_key
        http.verify_mode = @verify_mode
        http.open_timeout = @open_timeout
        http.read_timeout = @read_timeout
        http.use_ssl = @use_ssl
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @verify_ssl
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
