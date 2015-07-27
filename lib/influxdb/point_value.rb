module InfluxDB
  # Convert data point to string using Line protocol
  class PointValue
    attr_reader :series, :values, :tags, :timestamp

    def initialize(data)
      @series    = data[:series].gsub(/\s/, '\ ').gsub(',', '\,')
      @values    = data_to_string(data[:values], true)
      @tags      = data_to_string(data[:tags])
      @timestamp = data[:timestamp]
    end

    def dump
      dump = "#{@series}"
      dump << ",#{@tags}" if @tags
      dump << " #{@values}"
      dump << " #{@timestamp}" if @timestamp
      dump
    end

    private

    def data_to_string(data, quote_escape = false)
      return nil unless data && !data.empty?
      mappings = map(data, quote_escape)
      mappings.join(',')
    end

    def map(data, quote_escape)
      data.map do |k, v|
        key = escape_key(k)
        val = v.is_a?(String) ? escape_value(v, quote_escape) : v
        "#{key}=#{val}"
      end
    end

    def escape_value(value, quote_escape)
      val = value.
        gsub(/\s/, '\ ').
        gsub(',', '\,').
        gsub('"', '\"')
      val = %("#{val}") if quote_escape
      val
    end

    def escape_key(key)
      key.to_s.gsub(/\s/, '\ ').gsub(',', '\,')
    end
  end
end
