module InfluxDB
  # Convert data point to string using Line protocol
  class PointValue
    attr_reader :series, :values, :tags, :timestamp

    def initialize(data)
      @series    = escape(data[:series], :measurement)

      @values    = data[:values].map{|k, v|
        key = escape(k.to_s, :field_key)
        val = if v.is_a?(String)
                '"' + escape(v, :field_value) + '"'
              else
                v.to_s
              end
        "#{key}=#{val}"
      }.join(',') if data[:values]

      @tags      = data[:tags].map{|k, v|
        key = escape(k.to_s, :tag_key)
        val = escape(v.to_s, :tag_value)
        "#{key}=#{val}"
      }.join(',') if data[:tags]

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

    ESCAPES = {
      measurement: [' ', ','],
      tag_key:   ['=', ' ', ','],
      tag_value: ['=', ' ', ','],
      field_key: ['=', ' ', ',', '"'],
      field_value: ['"'],
    }

    def escape(s, type)
      ESCAPES[type].each do |ch|
        s = s.gsub(ch){ "\\#{ch}" }
      end
      s
    end
  end
end
