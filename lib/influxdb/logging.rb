require 'logger'

module InfluxDB
  module Logging # :nodoc:
    PREFIX = "[InfluxDB] "

    class << self
      attr_writer :logger
    end

    def self.logger
      @logger ||= ::Logger.new(STDERR).tap { |logger| logger.level = Logger::INFO }
    end

    private

    def log(level, message)
      InfluxDB::Logging.logger.send(level.to_sym, PREFIX + message) if InfluxDB::Logging.logger
    end
  end
end
