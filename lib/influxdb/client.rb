require 'json'
require 'cause' unless Exception.instance_methods.include?(:cause)
require 'thread'

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
    def initialize(*args)
      opts = args.last.is_a?(Hash) ? args.last : {}
      opts[:database] = args.first if args.first.is_a? String
      @config = InfluxDB::Config.new(opts)
      @stopped = false
      @writer = find_writer

      at_exit { stop! } if config.retry > 0
    end

    def stop!
      writer.worker.stop! if config.async?
      @stopped = true
    end

    def stopped?
      @stopped
    end

    private

    def find_writer
      if config.async?
        InfluxDB::Writer::Async.new(self, config.async)
      elsif config.udp?
        InfluxDB::Writer::UDP.new(self, config.udp)
      else
        self
      end
    end
  end
end
