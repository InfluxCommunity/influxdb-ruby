module InfluxDB
  # Convert data point to string using Line protocol
  class PointValue
    attr_reader :series, :values, :tags, :timestamp

    def initialize(data)
      @series    = data[:series].gsub(/\s/, '\ ')
      @values    = stringify(data[:values])
      @tags      = stringify(data[:tags])
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

    def stringify(hash)
      return nil unless hash && !hash.empty?
      hash.map do |k, v|
        key = k.to_s.gsub(/\s/, '\ ')
        val = v.is_a?(String) ? v.gsub(/\s/, '\ ') : v
        "#{key}=#{val}"
      end.join(',')
    end
  end
end
