module InfluxDB #:nodoc:
  TIMESTAMP_CONVERSIONS = {
    "ns" => 1e9.to_r,
    nil  => 1e9.to_r,
    "u"  => 1e6.to_r,
    "ms" => 1e3.to_r,
    "s"  => 1.to_r,
    "m"  => 1.to_r / 60,
    "h"  => 1.to_r / 60 / 60,
  }.freeze
  private_constant :TIMESTAMP_CONVERSIONS

  # Converts a Time to a timestamp with the given precision.
  #
  # `convert_timestamp(Time.now, "ms")` might return `1543533308243`.
  def self.convert_timestamp(time, time_precision)
    factor = TIMESTAMP_CONVERSIONS.fetch(time_precision) do
      raise "Invalid time precision: #{time_precision}"
    end

    (time.to_r * factor).to_i
  end
end
