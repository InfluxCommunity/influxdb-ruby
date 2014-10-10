require 'logger'

module InfluxDB
  module Logging
    PREFIX = "[InfluxDB] "

    def self.logger=(new_logger)
      @logger = new_logger
    end

    def self.logger
      return @logger unless @logger.nil?
      @logger = ::Logger.new(STDERR).tap {|logger| logger.level = Logger::INFO}
    end

    private
    def log(level, message)
      InfluxDB::Logging.logger.send(level.to_sym, PREFIX + message) if InfluxDB::Logging.logger
    end
  end
end
