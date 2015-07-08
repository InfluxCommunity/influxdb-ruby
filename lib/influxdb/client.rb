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

    def create_database(name)
      execute("CREATE DATABASE #{name}")
    end

    def delete_database(name)
      execute("DROP DATABASE #{name}")
    end

    # => [{"name"=>"mydb"}, {"name"=>"testdb"}]
    def get_database_list
      resp = execute("SHOW DATABASES", parse: true)
      values = resp["results"][0]["series"][0]["values"]
      values && !values.empty? ? values.flatten.map {|v| { "name" => v }} : []
    end

    def create_cluster_admin(username, password)
      execute("CREATE USER #{username} WITH PASSWORD '#{password}' WITH ALL PRIVILEGES")
    end

    def get_cluster_admin_list
      get_user_list.select{|u| u['admin']}.map {|u| u.delete_if {|k,_| k == 'admin'}}
    end

    # create_database_user('testdb', 'user', 'pass') => grants all privileges by default
    # create_database_user('testdb', 'user', 'pass', :permissions => :read) => use [:read|:write|:all]
    def create_database_user(database, username, password, options={})
      permissions = options[:permissions] || 'ALL'
      execute("CREATE user #{username} WITH PASSWORD '#{password}'; GRANT #{permissions.to_s.upcase} ON #{database} TO #{username}")
    end

    def update_user_password(username, password)
      execute("SET PASSWORD FOR #{username} = '#{password}'")
    end

    # permission => [:read|:write|:all]
    def grant_user_privileges(username, database, permission)
      execute("GRANT #{permission.to_s.upcase} ON #{database} TO #{username}")
    end

    # permission => [:read|:write|:all]
    def revoke_user_privileges(username, database, permission)
      execute("REVOKE #{permission.to_s.upcase} ON #{database} FROM #{username}")
    end

    def revoke_cluster_admin_privileges(username)
      execute("REVOKE ALL PRIVILEGES FROM #{username}")
    end

    def delete_user(username)
      execute("DROP USER #{username}")
    end

    # => [{"username"=>"usr", "admin"=>true}, {"username"=>"justauser", "admin"=>false}]
    def get_user_list
      resp = execute("SHOW USERS", parse: true)
      values = resp["results"][0]["series"][0]["values"]
      values && !values.empty? ? values.map {|v| {'username' => v.first, 'admin' => v.last}} : []
    end

    def continuous_queries(database)
      resp = execute("SHOW CONTINUOUS QUERIES", parse: true)
      data = resp["results"][0]["series"].select {|v| v["name"] == database}
      values = data.try(:[], 0).try(:[], "values")
      values && !values.empty? ? values.map {|v| {'name' => v.first, 'query' => v.last}} : []
    end

    # TODO
    def get_shard_list()
    #   get full_url("/cluster/shards")
    end

    # TODO
    def delete_shard(shard_id, server_ids)
      # data = JSON.generate({"serverIds" => server_ids})
      # delete full_url("/cluster/shards/#{shard_id}"), data
    end

    # TODO
    def delete_series(series)
      # delete full_url("/db/#{@database}/series/#{series}")
    end

    # Example:
    #
    # Single point:
    # write_points(series: 'cpu', tags: {region: 'us'}, values: {internal: 66})
    #
    # Multiple points:
    # write_points([
    #   {
    #     series: 'cpu',
    #     tags: { host: 'server_nl', regios: 'us' },
    #     values: {internal: 5, external: 6},
    #     timestamp: 1422568543702900257
    #   },
    #   {
    #     series: 'gpu',
    #     values: {value: 0.9999},
    #   }
    # ])
    #
    # NOTE: +tags+ are optional
    # NOTE: +timestamp+ is optional, if you decide to provide it, remember to
    # keep it compatible with requested time_precision
    def write_points(data, async=@async, time_precision=@time_precision)
      data = data.is_a?(Array) ? data : [data]
      payload = data.map do |point|
        InfluxDB::PointValue.new(point).dump
      end.join("\n")

      if async
        worker.push(payload)
      elsif udp_client
        udp_client.send(payload)
      else
        _write(payload, time_precision)
      end
    end

    # Example:
    # write_point('cpu', tags: {region: 'us'}, values: {internal: 60})
    def write_point(series, data, async=@async, time_precision=@time_precision)
      data.merge!(series: series)
      write_points(data, async, time_precision)
    end

    def _write(payload, time_precision=@time_precision)
      url = full_url("/write", db: @database, precision: time_precision)
      post(url, payload)
    end

    def query(query, time_precision=@time_precision)
      url = full_url("/query", q: query, db: database, precision: time_precision)
      resp = get(url, parse: true)
      series = resp["results"][0]["series"]
      return nil unless series && !series.empty?

      if block_given?
        series.each { |s| yield s['name'], s['tags'], denormalize_series(s) }
      else
        series.map do |s|
          {
            'name' => s['name'],
            'tags' => s['tags'],
            'values' => denormalize_series(s)
          }
        end
      end
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

    def execute(query, params={})
      url = full_url("/query", q: query)
      get(url, params)
    end

    def get(url, params={})
      connect_with_retry do |http|
        request = Net::HTTP::Get.new(url)
        request.basic_auth @username, @password if basic_auth?
        response = http.request(request)
        if response.kind_of? Net::HTTPSuccess
          parsed_response = JSON.parse(response.body) if response.body
          if response_with_errors(parsed_response)
            raise InfluxDB::QueryError.new parsed_response
          elsif params[:parse]
            parsed_response
          else
            response
          end
        elsif response.kind_of? Net::HTTPUnauthorized
          raise InfluxDB::AuthenticationError.new response.body
        else
          raise InfluxDB::Error.new response.body
        end
      end
    end

    def post(url, data)
      headers = {"Content-Type" => "application/octet-stream"}
      connect_with_retry do |http|
        request = Net::HTTP::Post.new(url, headers)
        request.basic_auth @username, @password if basic_auth?
        request.body = data
        response = http.request(request)
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

    def denormalize_series(series)
      series["values"].map do |values|
        Hash[series["columns"].zip(values)]
      end
    end

    def response_with_errors(response)
      response && response.is_a?(Hash) && response["results"][0]["error"]
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
