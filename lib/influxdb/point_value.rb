module InfluxDB
  # Convert data point to string using Line protocol
  class PointValue
    attr_reader :series, :values, :tags, :timestamp

    def initialize(data)
      @series    = escape data[:series], :measurement
      @values    = escape_values data[:values]
      @tags      = escape_tags data[:tags]

      @timestamp = data[:timestamp]
    end

    def dump
      dump =  @series.dup
      dump << ",#{@tags}" if @tags
      dump << " #{@values}"
      dump << " #{@timestamp}" if @timestamp
      dump
    end

    private

    ESCAPES = {
      measurement:  [' '.freeze, ','.freeze],
      tag_key:      ['='.freeze, ' '.freeze, ','.freeze],
      tag_value:    ['='.freeze, ' '.freeze, ','.freeze],
      field_key:    ['='.freeze, ' '.freeze, ','.freeze, '"'.freeze],
      field_value:  ['"'.freeze]
    }.freeze

    def escape(s, type)
      ESCAPES[type].each do |ch|
        s = s.gsub(ch) { "\\#{ch}" }
      end
      s
    end

    def map(data, quote_escape)
      data.map do |k, v|
        key = escape_key(k)
        val = v.is_a?(String) ? escape_value(v, quote_escape) : v
        val = val.is_a?(Integer) ? "#{val}i" : v
        "#{key}=#{val}"
      end
    end

    def escape_values(values)
      return if values.nil?
      values.map do |k, v|
        key = escape(k.to_s, :field_key)
        val = if v.is_a?(String)
                '"' + escape(v, :field_value) + '"'
              else
                v.to_s
              end
        "#{key}=#{val}"
      end.join(",")
    end

    def escape_tags(tags)
      return if tags.nil?
      tags.map do |k, v|
        key = escape(k.to_s, :tag_key)
        val = escape(v.to_s, :tag_value)
        "#{key}=#{val}"
      end.join(",")
    end
  end
end
