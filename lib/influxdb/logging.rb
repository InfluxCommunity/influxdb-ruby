require 'logger'

module InfluxDB
  module Logging # :nodoc:
    PREFIX = "InfluxDB".freeze

    class << self
      attr_writer :logger
      attr_writer :log_level

      def logger
        return false if @logger == false

        @logger ||= ::Logger.new(STDERR).tap { |logger| logger.level = Logger::INFO }
      end

      def log_level
        @log_level || Logger::INFO
      end

      def log?(level)
        case level
        when :debug then log_level <= Logger::DEBUG
        when :info  then log_level <= Logger::INFO
        when :warn  then log_level <= Logger::WARN
        when :error then log_level <= Logger::ERROR
        when :fatal then log_level <= Logger::FATAL
        else true
        end
      end
    end

    private

    def log(level, message = nil, &block)
      return unless InfluxDB::Logging.logger
      return unless InfluxDB::Logging.log?(level)

      if block_given?
        InfluxDB::Logging.logger.send(level.to_sym, PREFIX, &block)
      else
        InfluxDB::Logging.logger.send(level.to_sym, PREFIX) { message }
      end
    end
  end
end
