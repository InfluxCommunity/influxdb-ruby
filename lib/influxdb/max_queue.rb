require "thread"

module InfluxDB
  # Queue with max length limit
  class MaxQueue < Queue
    attr_reader :max

    def initialize(max = 10_000)
      raise ArgumentError, "queue size must be positive" if max <= 0
      @max = max
      super()
    end

    def push(obj)
      super if length < @max
    end
  end
end
