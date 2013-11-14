module InfluxDB
  module Logger
    PREFIX = "[InfluxDB] "

    private
    def log(level, message)
      STDERR.puts(PREFIX + "(#{level}) #{message}") unless level == :debug
    end
  end
end
