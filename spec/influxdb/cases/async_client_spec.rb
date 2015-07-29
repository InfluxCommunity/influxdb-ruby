require "spec_helper"
require "timeout"

describe InfluxDB::Client do
  let(:subject) { described_class.new(async: true) }
  let(:stub_url) { "http://localhost:8086/write?db=&p=root&precision=s&u=root" }
  let(:worker_klass) { InfluxDB::Writer::Async::Worker }

  specify { expect(subject.writer).to be_a(InfluxDB::Writer::Async) }

  describe "#write_point" do
    let(:payload) { "responses,region=eu value=5" }

    it "sends writes to client" do
      post_request = stub_request(:post, stub_url)

      (worker_klass::MAX_POST_POINTS + 100).times do
        subject.write_point('a', {})
      end

      Timeout.timeout(2 * worker_klass::SLEEP_INTERVAL) do
        subject.stop!
        # ensure threads exit
        subject.writer.worker.threads.each(&:join)

        # flush queue (we cannot test `at_exit`)
        subject.writer.worker.check_background_queue
      end

      # exact times can be 2 or 3 (because we have 3 worker threads),
      # but cannot be less than 2 due to MAX_POST_POINTS limit
      expect(post_request).to have_been_requested.at_least_times(2)
    end
  end
end
