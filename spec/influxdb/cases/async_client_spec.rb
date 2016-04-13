require "spec_helper"
require "timeout"

describe InfluxDB::Client do
  let(:subject) { described_class.new(async: true) }
  let(:stub_url) { "http://localhost:8086/write?db=&p=root&precision=s&u=root" }
  let(:worker_klass) { InfluxDB::Writer::Async::Worker }

  specify { expect(subject.writer).to be_a(InfluxDB::Writer::Async) }

  describe "#write_point" do
    it "sends writes to client" do
      post_request = stub_request(:post, stub_url)

      (worker_klass::MAX_POST_POINTS + 100).times do
        subject.write_point('a', {})
      end

      # The timout code is fragile, and heavily dependent on system load
      # (and scheduler decisions). On the CI, the system is less
      # responsive and needs a bit more time.
      timeout_stretch = ENV["TRAVIS"] == "true" ? 10 : 3

      Timeout.timeout(timeout_stretch * worker_klass::SLEEP_INTERVAL) do
        subject.stop!
      end

      subject.writer.worker.threads.each do |t|
        expect(t.stop?).to be true
      end

      # exact times can be 2 or 3 (because we have 3 worker threads),
      # but cannot be less than 2 due to MAX_POST_POINTS limit
      expect(post_request).to have_been_requested.at_least_times(2)
    end
  end
end
