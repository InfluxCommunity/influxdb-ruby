require "spec_helper"
require 'timeout'

describe InfluxDB::Writer::Async::Worker do
  let(:fake_client) { double(stopped?: false) }
  let(:worker) { described_class.new(fake_client, {}) }

  describe "#push" do
    let(:payload) { { name: "juan", age: 87, time: Time.now.to_i } }

    it "writes to the client" do
      queue = Queue.new
      expect(fake_client).to receive(:write).once.with([payload]) do |_data|
        queue.push(:received)
      end
      worker.push(payload)

      Timeout.timeout(described_class::SLEEP_INTERVAL) do
        queue.pop
      end
    end
  end
end
