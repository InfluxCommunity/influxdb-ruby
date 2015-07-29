require "spec_helper"
require 'timeout'

describe InfluxDB::Writer::Async::Worker do
  let(:fake_client) { double(stopped?: false) }
  let(:worker) { described_class.new(fake_client, {}) }

  describe "#push" do
    let(:payload1) { "responses,region=eu value=5" }
    let(:payload2) { "responses,region=eu value=6" }
    let(:aggregate) { "#{payload1}\n#{payload2}" }

    it "writes aggregate payload to the client" do
      queue = Queue.new
      allow(fake_client).to receive(:write) do |data, _precision|
        queue.push(data)
      end
      worker.push(payload1)
      worker.push(payload2)

      Timeout.timeout(described_class::SLEEP_INTERVAL) do
        result = queue.pop
        expect(result).to eq aggregate
      end
    end
  end
end
