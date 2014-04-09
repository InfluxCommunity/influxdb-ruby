require 'thread'
require "net/http"
require "uri"

module InfluxDB
  class Worker
    attr_reader :client
    attr_accessor :queue

    include InfluxDB::Logging

    MAX_POST_POINTS = 1000
    NUM_WORKER_THREADS = 3
    SLEEP_INTERVAL = 5

    def initialize(client)
      @queue = InfluxDB::MaxQueue.new
      @client = client
      spawn_threads!
    end

    def current_threads
      Thread.list.select {|t| t[:influxdb] == self.object_id}
    end

    def current_thread_count
      Thread.list.count {|t| t[:influxdb] == self.object_id}
    end

    def push(payload)
      queue.push(payload)
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

          while !client.stopped?
            self.check_background_queue(thread_num)
            sleep rand(SLEEP_INTERVAL)
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
          data.push p
        end

        return if data.empty?

        begin
          log :debug, "Found data in the queue! (#{data.length} points)"
          @client._write(data)
        rescue => e
          puts "Cannot write data: #{e.inspect}"
        end
      end while @queue.length > MAX_POST_POINTS
    end
  end
end
