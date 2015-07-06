module InfluxDB

  class PointValue

    def initialize(data)
      @series    = data[:series]
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
      hash.blank? ? nil : hash.map{|k,v| "#{k}=#{v}"}.join(',')
    end
  end
end
