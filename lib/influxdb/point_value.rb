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
      dump << " ".freeze if dump[-1] == "\\"
      dump << " #{@values}"
      dump << " #{@timestamp}" if @timestamp
      dump
    end

    private

    ESCAPES = {
      measurement: [' '.freeze, ','.freeze],
      tag_key:     ['='.freeze, ' '.freeze, ','.freeze],
      tag_value:   ['='.freeze, ' '.freeze, ','.freeze],
      field_key:   ['='.freeze, ' '.freeze, ','.freeze, '"'.freeze],
      field_value: ["\\".freeze, '"'.freeze],
    }.freeze

    private_constant :ESCAPES

    def escape(str, type)
      # rubocop:disable Layout/AlignParameters
      str = str.encode "UTF-8".freeze, "UTF-8".freeze,
        invalid: :replace,
        undef:   :replace,
        replace: "".freeze
      # rubocop:enable Layout/AlignParameters

      ESCAPES[type].each do |ch|
        str = str.gsub(ch) { "\\#{ch}" }
      end
      str
    end

    def escape_values(values)
      return if values.nil?

      values.map do |k, v|
        key = escape(k.to_s, :field_key)
        val = escape_value(v)
        "#{key}=#{val}"
      end.join(",".freeze)
    end

    def escape_value(value)
      if value.is_a?(String)
        '"'.freeze + escape(value, :field_value) + '"'.freeze
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

        "#{key}=#{val}" unless key == "".freeze || val == "".freeze
      end.compact

      tags.join(",") unless tags.empty?
    end
  end
end
