require 'json'
require 'cause'

module InfluxDB
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize

  # InfluxDB client class
  class Client
    attr_reader :config, :writer

    include InfluxDB::Logging
    include InfluxDB::HTTP
    include InfluxDB::Query::Core
    include InfluxDB::Query::Cluster
    include InfluxDB::Query::Database
    include InfluxDB::Query::Shard
    include InfluxDB::Query::Series
    include InfluxDB::Query::User

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
    # +:path+:: the specified path prefix when building the url e.g.: /prefix/db/dbname...
    # +:username+:: the username to use when executing commands
    # +:password+:: the password associated with the username
    # +:use_ssl+:: use ssl to connect
    def initialize(*args)
      opts = args.last.is_a?(Hash) ? args.last : {}
      opts[:database] = args.first if args.first.is_a? String
      @config = InfluxDB::Config.new(opts)
      @stopper = false

      @writer = self

      if config.async?
        @writer = InfluxDB::Writer::Async.new(self, config.async)
      elsif config.udp?
        @writer = InfluxDB::Writer::UDP.new(self, config.udp)
      end

      at_exit { stop! }
    end

    # Write several points
    #
    # @example
    # client.write_points(
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
    def write_points(points)
      # todo:
    end

    # Write data point for series `name`
    def write_point(name, data)
      data = data.is_a?(Array) ? data : [data]
      columns = data.reduce(:merge).keys.sort { |a, b| a.to_s <=> b.to_s }
      payload = { name: name, points: [], columns: columns }

      data.each do |point|
        payload[:points] << columns.inject([]) do |array, column|
          array << InfluxDB::PointValue.new(point[column]).dump
        end
      end

      write_raw [payload]
    end

    # Write raw data to InfluxDB
    def write_raw(payload)
      writer.write(payload)
    end

    def stop!
      @stopped = true
    end

    def stopped?
      @stopped
    end
  end
end
