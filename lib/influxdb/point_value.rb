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
      # rubocop:disable Style/AlignParameters
      s = s.encode "UTF-8".freeze, "UTF-8".freeze,
        invalid: :replace,
        undef: :replace,
        replace: "".freeze

      ESCAPES[type].each do |ch|
        s = s.gsub(ch) { "\\#{ch}" }
      end
      s
    end

    def escape_values(values)
      return if values.nil?
      values.map do |k, v|
        key = escape(k.to_s, :field_key)
        val = escape_value(v)
        "#{key}=#{val}"
      end.join(",")
    end

    def escape_value(value)
      if value.is_a?(String)
        '"' + escape(value, :field_value) + '"'
      elsif value.is_a?(Integer)
        "#{value}i"
      else
        value.to_s
      end
    end

    def escape_tags(tags)
      return if tags.nil?

      tags = tags.map do |k, v|
        key = escape(k.to_s, :tag_key)
        val = escape(v.to_s, :tag_value)

        "#{key}=#{val}" unless key == "" || val == ""
      end.compact

      tags.join(",") unless tags.empty?
    end
  end
end
