require 'json'

module InfluxDB
  # InfluxDB client class
  class Client
    attr_reader :config, :writer

    include InfluxDB::Logging
    include InfluxDB::HTTP
    include InfluxDB::Query::Core
    include InfluxDB::Query::Cluster
    include InfluxDB::Query::Database
    include InfluxDB::Query::User
    include InfluxDB::Query::ContinuousQuery
    include InfluxDB::Query::RetentionPolicy
    include InfluxDB::Query::Series
    include InfluxDB::Query::Measurement

    # Initializes a new InfluxDB client
    #
    # === Examples:
    #
    #  # connect to localhost using root/root
    #  # as the credentials and doesn't connect to a db
    #
    #  InfluxDB::Client.new
    #
    #  # connect to localhost using root/root
    #  # as the credentials and 'db' as the db name
    #
    #  InfluxDB::Client.new 'db'
    #
    #  # override username, other defaults remain unchanged
    #
    #  InfluxDB::Client.new username: 'username'
    #
    #  # override username, use 'db' as the db name
    #  Influxdb::Client.new 'db', username: 'username'
    #
    # === Valid options in hash
    #
    # +:host+:: the hostname to connect to
    # +:port+:: the port to connect to
    # +:prefix+:: the specified path prefix when building the url e.g.: /prefix/db/dbname...
    # +:username+:: the username to use when executing commands
    # +:password+:: the password associated with the username
    # +:use_ssl+:: use ssl to connect
    # +:verify_ssl+:: verify ssl server certificate?
    # +:ssl_ca_cert+:: ssl CA certificate, chainfile or CA path.
    #                  The system CA path is automatically included
    # +:retry+:: number of times a failed request should be retried. Defaults to infinite.
    def initialize(database = nil, **opts)
      opts[:database] = database if database.is_a? String
      @config = InfluxDB::Config.new(opts)
      @stopped = false
      @writer = find_writer

      at_exit { stop! }
    end

    def stop!
      if config.async?
        # If retry was infinite (-1), set it to zero to give the main thread one
        # last chance to flush the queue
        config.retry = 0 if config.retry < 0
        writer.worker.stop!
      end
      @stopped = true
    end

    def stopped?
      @stopped
    end

    def now
      InfluxDB.now(config.time_precision)
    end

    private

    def find_writer
      if config.async?
        InfluxDB::Writer::Async.new(self, config.async)
      elsif config.udp.is_a?(Hash)
        InfluxDB::Writer::UDP.new(self, **config.udp)
      elsif config.udp?
        InfluxDB::Writer::UDP.new(self)
      else
        self
      end
    end
  end
end
