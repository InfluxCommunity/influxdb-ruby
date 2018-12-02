module InfluxDB #:nodoc:
  # Converts a Time to a timestamp with the given precision.
  #
  # === Example
  #
  #  InfluxDB.convert_timestamp(Time.now, "ms")
  #  #=> 1543533308243
  def self.convert_timestamp(time, precision = "s")
    factor = TIME_PRECISION_FACTORS.fetch(precision) do
      raise ArgumentError, "invalid time precision: #{precision}"
    end

    (time.to_r * factor).to_i
  end

  # Returns the current timestamp with the given precision.
  #
  # Implementation detail: This does not create an intermediate Time
  # object with `Time.now`, but directly requests the CLOCK_REALTIME,
  # which in general is a bit faster.
  #
  # This is useful, if you want or need to shave off a few microseconds
  # from your measurement.
  #
  # === Examples
  #
  #  InfluxDB.now("ns")   #=> 1543612126401392625
  #  InfluxDB.now("u")    #=> 1543612126401392
  #  InfluxDB.now("ms")   #=> 1543612126401
  #  InfluxDB.now("s")    #=> 1543612126
  #  InfluxDB.now("m")    #=> 25726868
  #  InfluxDB.now("h")    #=> 428781
  def self.now(precision = "s")
    name, divisor = CLOCK_NAMES.fetch(precision) do
      raise ArgumentError, "invalid time precision: #{precision}"
    end

    time = Process.clock_gettime Process::CLOCK_REALTIME, name
    (time / divisor).to_i
  end

  TIME_PRECISION_FACTORS = {
    "ns" => 1e9.to_r,
    nil  => 1e9.to_r,
    "u"  => 1e6.to_r,
    "ms" => 1e3.to_r,
    "s"  => 1.to_r,
    "m"  => 1.to_r / 60,
    "h"  => 1.to_r / 60 / 60,
  }.freeze
  private_constant :TIME_PRECISION_FACTORS

  CLOCK_NAMES = {
    "ns" => [:nanosecond, 1],
    nil  => [:nanosecond, 1],
    "u"  => [:microsecond, 1],
    "ms" => [:millisecond, 1],
    "s"  => [:second, 1],
    "m"  => [:second, 60.to_r],
    "h"  => [:second, (60 * 60).to_r],
  }.freeze
  private_constant :CLOCK_NAMES
end
