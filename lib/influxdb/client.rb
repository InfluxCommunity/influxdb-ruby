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
      # url = full_url("/db")
      # options[:name] = name
      # data = JSON.generate(options)
      # post(url, data)
      execute("CREATE DATABASE #{name}")
    end

    def delete_database(name)
      # delete full_url("/db/#{name}")
      execute("DROP DATABASE #{name}")
    end

    # => [{"name"=>"mydb"}, {"name"=>"testdb"}]
    def get_database_list
      # get full_url("/db")
      resp = execute("SHOW DATABASES", parse: true)
      resp["results"][0]["series"][0]["values"].flatten.map {|v| { "name" => v }}
    end

    def create_cluster_admin(username, password)
      # url = full_url("/cluster_admins")
      # data = JSON.generate({:name => username, :password => password})
      # post(url, data)
      execute("CREATE USER #{username} WITH PASSWORD '#{password}' WITH ALL PRIVILEGES")
    end

    # DEPRECATED, use update_user_password
    # def update_cluster_admin(username, password)
      # url = full_url("/cluster_admins/#{username}")
      # data = JSON.generate({:password => password})
      # post(url, data)
    # end

    # DEPRECATED, use delete_user
    # def delete_cluster_admin(username)
      # delete full_url("/cluster_admins/#{username}")
    # end

    def get_cluster_admin_list
      # get full_url("/cluster_admins")
      get_user_list.select{|u| u['admin']}.map {|u| u.except('admin')}
    end

    # create_database_user('testdb', 'user', 'pass') => grants all privileges by default
    # create_database_user('testdb', 'user', 'pass', :permissions => :read) => use [:read|:write|:all]
    def create_database_user(database, username, password, options={})
      # url = full_url("/db/#{database}/users")
      # data = JSON.generate({:name => username, :password => password}.merge(options))
      # post(url, data)
      permissions = options[:permissions] || 'ALL'
      execute("CREATE user #{username} WITH PASSWORD '#{password}'; GRANT #{permissions.to_s.upcase} ON #{database} TO #{username}")
    end

    # DEPRECATED, use:
    # * update_user_password
    # * grant_user_privileges
    # def update_database_user(database, username, options = {})
      # url = full_url("/db/#{database}/users/#{username}")
      # data = JSON.generate(options)
      # post(url, data)
    # end

    ###################### NEW METHODS ########################
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

    # => {"username"=>"usr", "admin"=>true}, {"username"=>"justauser", "admin"=>false}]
    def get_user_list
      resp = execute("SHOW USERS", parse: true)
      resp["results"][0]["series"][0]["values"].map do |v|
        {'username' => v.first, 'admin' => v.last}
      end
    end
    ############################################################

    # DEPRECATED, use delete_user
    # def delete_database_user(database, username)
      # delete full_url("/db/#{database}/users/#{username}")
    # end

    # DEPRECATED, use get_user_list
    # def get_database_user_list(database)
      # get full_url("/db/#{database}/users")
    # end

    # DEPRECATED, get_user_list returns privileges
    # def get_database_user_info(database, username)
      # get full_url("/db/#{database}/users/#{username}")
    # end

    # DEPRECATED, use revoke_user_privileges & grant_user_privileges
    # def alter_database_privilege(database, username, admin=true)
      # update_database_user(database, username, :admin => admin)
    # end

    def continuous_queries(database)
      # get full_url("/db/#{database}/continuous_queries")
      resp = execute("SHOW CONTINUOUS QUERIES", parse: true)
      data = resp["results"][0]["series"].select {|v| v["name"] == database}.try(:[], 0).try(:[], "values")
      data.blank? ? [] : data.map {|v| {'name' => v.first, 'query' => v.last}}
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


    # data => {tags: {host: 'server', regios: 'us'}, values: {testcolumn: 0.5434, value: 0.434545}, timestamp: 1422568543702900257}
    # tags and timestamp are optional
    def write_point(series, data, async=@async, time_precision=@time_precision)

      data = data.is_a?(Array) ? data : [data]

      payload = data.map do |point|
        InfluxDB::PointValue.new(series, point).dump
      end.join("\n")

      if async
        worker.push(payload) # TODO: support
      elsif udp_client
        udp_client.send(payload) # TODO: support
      else
        _write(payload, time_precision)
      end
    end

    def _write(payload, time_precision=@time_precision)
      # url = full_url("/db/#{@database}/series", :time_precision => time_precision)
      # data = JSON.generate(payload)
      # post(url, data)
      url = full_url("/write", db: @database, precision: time_precision)
      post(url, payload)
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
          parsed_response = JSON.parse(response.body)
          if parsed_response["results"][0]["error"].present?
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
