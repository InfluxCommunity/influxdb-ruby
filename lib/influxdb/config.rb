require 'thread'

module InfluxDB
  # InfluxDB client configuration
  class Config
    AUTH_METHODS = ["params".freeze, "basic_auth".freeze, "none".freeze].freeze

    attr_accessor :port,
                  :username,
                  :password,
                  :database,
                  :time_precision,
                  :use_ssl,
                  :verify_ssl,
                  :ssl_ca_cert,
                  :auth_method,
                  :initial_delay,
                  :max_delay,
                  :open_timeout,
                  :read_timeout,
                  :retry,
                  :prefix,
                  :chunk_size,
                  :denormalize,
                  :epoch

    attr_reader :async, :udp

    def initialize(opts = {})
      extract_http_options!(opts)
      extract_ssl_options!(opts)
      extract_database_options!(opts)
      extract_writer_options!(opts)
      extract_query_options!(opts)

      configure_retry! opts.fetch(:retry, nil)
      configure_hosts! opts[:hosts] || opts[:host] || "localhost".freeze
    end

    def udp?
      udp != false
    end

    def async?
      async != false
    end

    def next_host
      host = @hosts_queue.pop
      @hosts_queue.push(host)
      host
    end

    def hosts
      Array.new(@hosts_queue.length) do
        host = @hosts_queue.pop
        @hosts_queue.push(host)
        host
      end
    end

    private

    # rubocop:disable Metrics/AbcSize
    def extract_http_options!(opts)
      @port           = opts.fetch :port, 8086
      @prefix         = opts.fetch :prefix, "".freeze
      @username       = opts.fetch :username, "root".freeze
      @password       = opts.fetch :password, "root".freeze
      @open_timeout   = opts.fetch :write_timeout, 5
      @read_timeout   = opts.fetch :read_timeout, 300
      @max_delay      = opts.fetch :max_delay, 30
      @initial_delay  = opts.fetch :initial_delay, 0.01
      auth            = opts[:auth_method]
      @auth_method    = AUTH_METHODS.include?(auth) ? auth : "params".freeze
    end

    def extract_ssl_options!(opts)
      @use_ssl      = opts.fetch :use_ssl, false
      @verify_ssl   = opts.fetch :verify_ssl, true
      @ssl_ca_cert  = opts.fetch :ssl_ca_cert, false
    end

    # normalize retry option
    def configure_retry!(value)
      case value
      when Integer
        @retry = value
      when true, nil
        @retry = -1
      when false
        @retry = 0
      end
    end

    # load the hosts into a Queue for thread safety
    def configure_hosts!(hosts)
      @hosts_queue = Queue.new
      Array(hosts).each do |host|
        @hosts_queue.push(host)
      end
    end

    def extract_database_options!(opts)
      @database       = opts[:database]
      @time_precision = opts.fetch :time_precision, "s".freeze
      @denormalize    = opts.fetch :denormalize, true
      @epoch          = opts.fetch :epoch, false
    end

    def extract_writer_options!(opts)
      @async = opts.fetch :async, false
      @udp   = opts.fetch :udp, false
    end

    def extract_query_options!(opts)
      @chunk_size = opts.fetch :chunk_size, nil
    end
  end
end
