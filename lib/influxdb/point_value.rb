require "date"

module InfluxDB
  # Convert data point to string using Line protocol
  class PointValue
    attr_reader :series, :values, :tags, :timestamp

    def initialize(data, options = {})
      options  ||= {}
      precision  = options.fetch(:precision, "s")

      @series    = escape data[:series], :measurement
      @values    = escape_values data[:values]
      @tags      = escape_tags data[:tags]
      @timestamp = escape_time data[:timestamp], precision
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
      field_value:  ['"'.freeze],
    }.freeze

    # Time in Ruby is based on the second, depending on the target
    # precision, we need to multiply the value by a constant amount.
    PRECISION_MULTIPLIER = {
      "ns"        => 10**9,             # nanosecond
      nil         => 10**9,             # nanosecond (alias)
      "u".freeze  => 10**6,             # microsecond
      "ms".freeze => 10**3,             # millisecond
      "s".freeze  => 1,                 # second
      "m".freeze  => Rational(1, 60),   # minute
      "h".freeze  => Rational(1, 3600), # hour
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

    def escape_time(t, precision)
      return t if t.nil? || t.is_a?(Integer) # ignore precision
      t = normalize_time(t)
      f = PRECISION_MULTIPLIER.fetch(precision, 1)
      (t.to_r * f).to_i
    end

    def normalize_time(t)
      # avoid time zone inherited from localtime(3), but only for Date
      # instances (DateTime < Date)
      if t.class == Date
        Time.utc(t.year, t.month, t.day)
      else
        (t.respond_to?(:to_time) ? t.to_time : t).getutc
      end
    end
  end
end
