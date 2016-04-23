require "spec_helper"
require "timeout"

describe InfluxDB::Client do
  let(:async_options) { true }
  let(:client) { described_class.new(async: async_options) }
  let(:subject) { client }
  let(:stub_url) { "http://localhost:8086/write?db=&p=root&precision=s&u=root" }
  let(:worker) { client.writer.worker }

  specify { expect(subject.writer).to be_a(InfluxDB::Writer::Async) }

  describe "#write_point" do
    it "sends writes to client" do
      post_request = stub_request(:post, stub_url).to_return(status: 204)

      (worker.max_post_points + 100).times do
        subject.write_point('a', {})
      end

      # The timout code is fragile, and heavily dependent on system load
      # (and scheduler decisions). On the CI, the system is less
      # responsive and needs a bit more time.
      timeout_stretch = ENV["TRAVIS"] == "true" ? 10 : 3

      Timeout.timeout(timeout_stretch * worker.sleep_interval) do
        subject.stop!
      end

      worker.threads.each do |t|
        expect(t.stop?).to be true
      end

      # exact times can be 2 or 3 (because we have 3 worker threads),
      # but cannot be less than 2 due to MAX_POST_POINTS limit
      expect(post_request).to have_been_requested.at_least_times(2)
    end
  end

  describe "async options" do
    let(:async_options) do
      {
        max_post_points:    10,
        max_queue_size:     100,
        num_worker_threads: 1,
        sleep_interval:     0.5
      }
    end

    subject { worker }
    before { worker.stop! }

    specify { expect(subject.max_post_points).to be 10 }
    specify { expect(subject.max_queue_size).to be 100 }
    specify { expect(subject.num_worker_threads).to be 1 }
    specify { expect(subject.sleep_interval).to be_within(0.0001).of(0.5) }
  end
end
