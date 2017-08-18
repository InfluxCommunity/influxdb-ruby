require "thread"

module InfluxDB
  # DEFAULT_CONFIG_OPTIONS maps (most) of the configuration options to
  # their default value. Each option (except for "async" and "udp") can
  # be changed at runtime throug the InfluxDB::Client instance.
  #
  # If you need to change the writer to be asynchronuous or use UDP, you
  # need to get a new InfluxDB::Client instance.
  DEFAULT_CONFIG_OPTIONS = {
    # HTTP connection options
    port:                 8086,
    prefix:               "".freeze,
    username:             "root".freeze,
    password:             "root".freeze,
    open_timeout:         5,
    read_timeout:         300,
    auth_method:          nil,

    # SSL options
    use_ssl:              false,
    verify_ssl:           true,
    ssl_ca_cert:          false,

    # Database options
    database:             nil,
    time_precision:       "s".freeze,
    epoch:                false,

    # Writer options
    async:                false,
    udp:                  false,
    discard_write_errors: false,

    # Retry options
    retry:                -1,
    max_delay:            30,
    initial_delay:        0.01,

    # Query options
    chunk_size:           nil,
    denormalize:          true,
  }.freeze

  # InfluxDB client configuration
  class Config
    # Valid values for the "auth_method" option.
    AUTH_METHODS = [
      "params".freeze,
      "basic_auth".freeze,
      "none".freeze,
    ].freeze

    ATTR_READER = %i[async udp].freeze
    private_constant :ATTR_READER

    ATTR_ACCESSOR = (DEFAULT_CONFIG_OPTIONS.keys - ATTR_READER).freeze
    private_constant :ATTR_ACCESSOR

    attr_reader(*ATTR_READER)
    attr_accessor(*ATTR_ACCESSOR)

    # Creates a new instance. See `DEFAULT_CONFIG_OPTIONS` for available
    # config options and their default values.
    def initialize(**opts)
      DEFAULT_CONFIG_OPTIONS.each do |name, value|
        set_ivar! name, opts.fetch(name, value)
      end

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

    def set_ivar!(name, value)
      case name
      when :auth_method
        value = "params".freeze unless AUTH_METHODS.include?(value)
      when :retry
        value = normalize_retry_option(value)
      end

      instance_variable_set "@#{name}", value
    end

    def normalize_retry_option(value)
      case value
      when Integer   then value
      when true, nil then -1
      when false     then 0
      end
    end

    # load the hosts into a Queue for thread safety
    def configure_hosts!(hosts)
      @hosts_queue = Queue.new
      Array(hosts).each do |host|
        @hosts_queue.push(host)
      end
    end
  end
end
