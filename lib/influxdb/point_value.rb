module InfluxDB

  class PointValue
    attr_accessor :values, :tags

    def initialize(series, data)
      @series    = series
      @values    = stringify(data[:values])
      @tags      = stringify(data[:tags])
      @timestamp = data[:timestamp]
    end

    def dump
      "#{@series},#{@tags} #{@values} #{@timestamp}"
    end

    private

    def stringify(hash)
      hash.blank? ? nil : hash.map{|k,v| "#{k}=#{v}"}.join(',')
    end
  end
end
