require 'json'

module InfluxDB
  class PointValue # :nodoc:
    attr_accessor :value

    def initialize(value)
      @value = value
    end

    def dump
      if value.is_a?(Array) || value.is_a?(Hash)
        JSON.generate(value)
      else
        value
      end
    end

    def load
      if maybe_json?
        begin
          JSON.parse(value)
        rescue JSON::ParserError
          value
        end
      else
        value
      end
    end

    def maybe_json?
      value.is_a?(String) && value =~ /\A(\{|\[).*(\}|\])$/
    end
  end
end
