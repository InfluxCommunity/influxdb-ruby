require 'logger'

module InfluxDB
  module Logging # :nodoc:
    PREFIX = "InfluxDB".freeze

    class << self
      attr_writer :logger
    end

    def self.logger
      return false if @logger == false
      @logger ||= ::Logger.new(STDERR).tap { |logger| logger.level = Logger::INFO }
    end

    private

    def log(level, message = nil, &block)
      return unless InfluxDB::Logging.logger
      if block_given?
        InfluxDB::Logging.logger.send(level.to_sym, PREFIX, &block)
      else
        InfluxDB::Logging.logger.send(level.to_sym, PREFIX) { message }
      end
    end
  end
end
