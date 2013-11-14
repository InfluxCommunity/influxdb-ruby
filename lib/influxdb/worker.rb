require 'thread'
require "net/http"
require "uri"

module InfluxDB
  module Worker
    attr_accessor :queue

    include InfluxDB::Logger

    MAX_POST_POINTS = 200
    NUM_WORKER_THREADS = 3
    SLEEP_INTERVAL = 500

    def current_threads
      Thread.list.select {|t| t[:influxdb] == self.object_id}
    end

    def current_thread_count
      Thread.list.count {|t| t[:influxdb] == self.object_id}
    end

    def spawn_threads!
      NUM_WORKER_THREADS.times do |thread_num|
        log :debug, "Spawning background worker thread #{thread_num}."

        Thread.new do
          Thread.current[:influxdb] = self.object_id

          at_exit do
            log :debug, "Thread exiting, flushing queue."
            check_background_queue(thread_num) until @queue.empty?
          end

          while true
            sleep SLEEP_INTERVAL
            self.check_background_queue(thread_num)
          end
        end
      end
    end

    def check_background_queue(thread_num = 0)
      log :debug, "Checking background queue on thread #{thread_num} (#{self.current_thread_count} active)"

      begin
        data = []

        while data.size < MAX_POST_POINTS && !@queue.empty?
          p = @queue.pop(true) rescue next;
          log :debug, "Found data in the queue! (#{p[:n]})"
          data.push p
        end

        _write(data)
      end while @queue.length > MAX_POST_POINTS
    end
  end
end
