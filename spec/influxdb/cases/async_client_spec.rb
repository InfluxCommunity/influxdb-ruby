require "spec_helper"
require "timeout"

describe InfluxDB::Client do
  let(:async_options) { { sleep_interval: 0.1 } }
  let(:client) { described_class.new(async: async_options) }
  let(:subject) { client }
  let(:stub_url) { "http://localhost:8086/write?db=&p=root&precision=s&u=root" }
  let(:worker) { client.writer.worker }

  specify { expect(subject.writer).to be_a(InfluxDB::Writer::Async) }

  describe "#write_point" do
    it "sends writes to client" do
      post_request = stub_request(:post, stub_url).to_return(status: 204)

      (worker.max_post_points + 100).times do |i|
        subject.write_point('a', values: { i: i })
      end

      sleep 1 until worker.threads.none? { |t| t[:influxdb].nil? }

      subject.stop!

      worker.threads.each do |t|
        expect(t.stop?).to be true
      end

      # exact times can be 2 or 3 (because we have 3 worker threads),
      # but cannot be less than 2 due to MAX_POST_POINTS limit
      expect(post_request).to have_been_requested.at_least_times(2)
    end

    context 'when precision, retention_policy and database are given' do
      let(:series)           { 'test_series' }
      let(:precision)        { 'test_precision' }
      let(:retention_policy) { 'test_period' }
      let(:database)         { 'test_database' }
      let(:async_options)    { { num_worker_threads: 1, sleep_interval: 0.1 } }

      it "writes aggregate payload to the client" do
        queue = Queue.new
        allow(client).to receive(:write) do |*args|
          queue.push(args)
        end

        subject.write_point(series, { values: { t: 60 } }, precision, retention_policy, database)
        subject.write_point(series, { values: { t: 61 } }, precision, retention_policy, database)

        sleep 1 until worker.threads.none? { |t| t[:influxdb].nil? }

        subject.stop!

        expect(queue.pop).to eq ["#{series} t=60i\n#{series} t=61i", precision, retention_policy, database]
      end

      context 'when different precision, retention_policy and database are given' do
        let(:precision2)        { 'test_precision2' }
        let(:retention_policy2) { 'test_period2' }
        let(:database2)         { 'test_database2' }

        it "writes separated payloads for each {precision, retention_policy, database} set" do
          queue = Queue.new
          allow(client).to receive(:write) do |*args|
            queue.push(args)
          end

          subject.write_point(series, { values: { t: 60 } }, precision,  retention_policy,  database)
          subject.write_point(series, { values: { t: 61 } }, precision2, retention_policy,  database)
          subject.write_point(series, { values: { t: 62 } }, precision,  retention_policy2, database)
          subject.write_point(series, { values: { t: 63 } }, precision,  retention_policy,  database2)

          sleep 1 until worker.threads.none? { |t| t[:influxdb].nil? }

          subject.stop!

          expect(queue.pop).to eq ["#{series} t=60i", precision,  retention_policy,  database]
          expect(queue.pop).to eq ["#{series} t=61i", precision2, retention_policy,  database]
          expect(queue.pop).to eq ["#{series} t=62i", precision,  retention_policy2, database]
          expect(queue.pop).to eq ["#{series} t=63i", precision,  retention_policy,  database2]
        end
      end
    end
  end

  describe "async options" do
    subject { worker }
    before { worker.stop! }

    context 'when all options are given' do
      let(:async_options) do
        {
          max_post_points:     10,
          max_queue_size:      100,
          num_worker_threads:  1,
          sleep_interval:      0.5,
          block_on_full_queue: false,
          shutdown_timeout:    0.6,
        }
      end

      it "uses the specified values" do
        expect(subject.max_post_points).to be 10
        expect(subject.max_queue_size).to be 100
        expect(subject.num_worker_threads).to be 1
        expect(subject.sleep_interval).to be_within(0.0001).of(0.5)
        expect(subject.block_on_full_queue).to be false
        expect(subject.queue).to be_kind_of(InfluxDB::MaxQueue)
        expect(subject.shutdown_timeout).to be_within(0.0001).of(0.6)
      end
    end

    context 'when only sleep_interval is given' do
      let(:async_options) { { sleep_interval: 0.2 } }

      it "uses a value for shutdown_timeout that is 2x sleep_interval" do
        expect(subject.sleep_interval).to be_within(0.0001).of(0.2)
        expect(subject.shutdown_timeout).to be_within(0.0001).of(0.4)
      end
    end

    context 'when only shutdown_timeout is given' do
      let(:async_options) { { shutdown_timeout: 0.3 } }

      it "uses that value" do
        expect(subject.sleep_interval).to be_within(0.0001).of(5)
        expect(subject.shutdown_timeout).to be_within(0.0001).of(0.3)
      end
    end
  end
end
