module InfluxDB
  # Convert data point to string using Line protocol
  class PointValue
    attr_reader :series, :values, :tags, :timestamp

    def initialize(data)
      @series    = data[:series].gsub(/\s/, '\ ').gsub(',','\,')
      @values    = stringify(data[:values], true)
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

    def stringify(hash, quote_escape = false)
      return nil unless hash && !hash.empty?
      hash.map do |k, v|
        key = k.to_s.gsub(/\s/, '\ ').gsub(',','\,')
        val = v
        if val.is_a?(String)
          val.gsub!(/\s/, '\ ')
          val.gsub!(',', '\,')
          val.gsub!('"', '\"')
          val = %{"#{val}"} if quote_escape
        end
        "#{key}=#{val}"
      end.join(',')
    end
  end
end
