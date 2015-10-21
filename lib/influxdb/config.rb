module InfluxDB
  # InfluxDB client configuration
  class Config
    AUTH_METHODS = %w(params basic_auth)

    attr_accessor :hosts,
                  :port,
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
                  :denormalize,
                  :epoch

    attr_reader :async, :udp

    # rubocop:disable all
    def initialize(opts = {})
      @database = opts[:database]
      @hosts = Array(opts[:hosts] || opts[:host] || ["localhost"])
      @port = opts.fetch(:port, 8086)
      @prefix = opts.fetch(:prefix, '')
      @username = opts.fetch(:username, "root")
      @password = opts.fetch(:password, "root")
      @auth_method = AUTH_METHODS.include?(opts[:auth_method]) ? opts[:auth_method] : "params"
      @use_ssl = opts.fetch(:use_ssl, false)
      @verify_ssl = opts.fetch(:verify_ssl, true)
      @ssl_ca_cert = opts.fetch(:ssl_ca_cert, false)
      @time_precision = opts.fetch(:time_precision, "s")
      @initial_delay = opts.fetch(:initial_delay, 0.01)
      @max_delay = opts.fetch(:max_delay, 30)
      @open_timeout = opts.fetch(:write_timeout, 5)
      @read_timeout = opts.fetch(:read_timeout, 300)
      @async = opts.fetch(:async, false)
      @udp = opts.fetch(:udp, false)
      @retry = opts.fetch(:retry, nil)
      @denormalize = opts.fetch(:denormalize, true)
      @epoch = opts.fetch(:epoch, false)
      @retry =
        case @retry
        when Integer
          @retry
        when true, nil
          -1
        when false
          0
        end
    end

    def udp?
      !!udp
    end

    def async?
      !!async
    end
  end
end
