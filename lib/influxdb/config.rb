require "uri"

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
    #
    # If you provide a "url" option, either as String (hint: ENV) or as
    # URI instance, you can override the defaults. The precedence for a
    # config value is as follows (first found wins):
    #
    # - values given in the options hash
    # - values found in URL (if given)
    # - default values
    def initialize(url: nil, **opts)
      opts = opts_from_url(url).merge(opts) if url

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

    # merges URI options into opts
    def opts_from_url(url)
      url = URI.parse(url) unless url.is_a?(URI)
      opts_from_non_params(url).merge opts_from_params(url.query)
    rescue URI::InvalidURIError
      {}
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity

    def opts_from_non_params(url)
      {}.tap do |o|
        o[:host]     = url.host        if url.host
        o[:port]     = url.port        if url.port
        o[:username] = url.user        if url.user
        o[:password] = url.password    if url.password
        o[:database] = url.path[1..-1] if url.path.length > 1
        o[:use_ssl]  = url.scheme == "https".freeze

        o[:udp] = { host: o[:host], port: o[:port] } if url.scheme == "udp"
      end
    end

    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity

    OPTIONS_FROM_PARAMS = (DEFAULT_CONFIG_OPTIONS.keys - %i[
      host port username password database use_ssl udp
    ]).freeze
    private_constant :OPTIONS_FROM_PARAMS

    def opts_from_params(query)
      params = CGI.parse(query || "").tap { |h| h.default = [] }

      OPTIONS_FROM_PARAMS.each_with_object({}) do |k, opts|
        next unless params[k.to_s].size == 1

        opts[k] = coerce(k, params[k.to_s].first)
      end
    end

    def coerce(name, value)
      case name
      when :open_timeout, :read_timeout, :max_delay, :retry, :chunk_size
        value.to_i
      when :initial_delay
        value.to_f
      when :verify_ssl, :denormalize, :async, :discard_write_errors
        %w[true 1 yes on].include?(value.downcase)
      else
        value
      end
    end
  end
end
