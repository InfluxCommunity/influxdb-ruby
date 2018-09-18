require "net/http"
require "uri"

module InfluxDB
  module Writer # :nodoc: all
    class Async
      attr_reader :config, :client

      def initialize(client, config)
        @client = client
        @config = config
      end

      def write(data, precision = nil, retention_policy = nil, database = nil)
        data = data.is_a?(Array) ? data : [data]
        data.map { |payload| worker.push(payload, precision, retention_policy, database) }
      end

      WORKER_MUTEX = Mutex.new
      def worker
        return @worker if @worker

        WORKER_MUTEX.synchronize do
          # this return is necessary because the previous mutex holder
          # might have already assigned the @worker
          return @worker if @worker

          @worker = Worker.new(client, config)
        end
      end

      class Worker
        attr_reader :client,
                    :queue,
                    :threads,
                    :max_post_points,
                    :max_queue_size,
                    :num_worker_threads,
                    :sleep_interval,
                    :block_on_full_queue

        include InfluxDB::Logging

        MAX_POST_POINTS     = 1000
        MAX_QUEUE_SIZE      = 10_000
        NUM_WORKER_THREADS  = 3
        SLEEP_INTERVAL      = 5
        BLOCK_ON_FULL_QUEUE = false

        def initialize(client, config)
          @client = client
          config = config.is_a?(Hash) ? config : {}

          @max_post_points     = config.fetch(:max_post_points,     MAX_POST_POINTS)
          @max_queue_size      = config.fetch(:max_queue_size,      MAX_QUEUE_SIZE)
          @num_worker_threads  = config.fetch(:num_worker_threads,  NUM_WORKER_THREADS)
          @sleep_interval      = config.fetch(:sleep_interval,      SLEEP_INTERVAL)
          @block_on_full_queue = config.fetch(:block_on_full_queue, BLOCK_ON_FULL_QUEUE)

          queue_class = @block_on_full_queue ? SizedQueue : InfluxDB::MaxQueue
          @queue = queue_class.new max_queue_size

          spawn_threads!
        end

        def push(payload, precision = nil, retention_policy = nil, database = nil)
          queue.push([payload, precision, retention_policy, database])
        end

        def current_threads
          Thread.list.select { |t| t[:influxdb] == object_id }
        end

        def current_thread_count
          Thread.list.count { |t| t[:influxdb] == object_id }
        end

        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize

        def spawn_threads!
          @threads = []
          num_worker_threads.times do |thread_num|
            log(:debug) { "Spawning background worker thread #{thread_num}." }

            @threads << Thread.new do
              Thread.current[:influxdb] = object_id

              until client.stopped?
                check_background_queue(thread_num)
                sleep rand(sleep_interval)
              end

              log(:debug) { "Exit background worker thread #{thread_num}." }
            end
          end
        end

        def check_background_queue(thread_num = 0)
          log(:debug) do
            "Checking background queue on thread #{thread_num} (#{current_thread_count} active)"
          end

          loop do
            data = {}

            while data.all? { |_, points| points.size < max_post_points } && !queue.empty?
              begin
                payload, precision, retention_policy, database = queue.pop(true)
                key = {
                  db: database,
                  pr: precision,
                  rp: retention_policy,
                }
                data[key] ||= []
                data[key] << payload
              rescue ThreadError
                next
              end
            end

            return if data.values.flatten.empty?

            begin
              log(:debug) { "Found data in the queue! (#{sizes(data)})" }
              write(data)
            rescue StandardError => e
              log :error, "Cannot write data: #{e.inspect}"
            end

            break if queue.length > max_post_points
          end
        end

        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize

        def stop!
          log(:debug) { "Thread exiting, flushing queue." }
          check_background_queue until queue.empty?
        end

        private

        def write(data)
          data.each do |key, points|
            client.write(points.join("\n"), key[:pr], key[:rp], key[:db])
          end
        end

        def sizes(data)
          data.map do |key, points|
            without_nils = key.reject { |_, v| v.nil? }
            if without_nils.empty?
              "#{points.size} points"
            else
              "#{key} => #{points.size} points"
            end
          end.join(', ')
        end
      end
    end
  end
end
