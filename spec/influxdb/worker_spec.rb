require "spec_helper"
require 'timeout'

describe InfluxDB::Worker do
  let(:fake_client) { double(:stopped? => false) }
  let(:worker) { InfluxDB::Worker.new(fake_client) }

  describe "#push" do
    let(:payload) { {:name => "juan", :age => 87, :time => Time.now.to_i} }

    it "should _write to the client" do
      queue = Queue.new
      expect(fake_client).to receive(:_write).once.with([payload]) do |data|
        queue.push(:received)
      end
      worker.push(payload)

      Timeout.timeout(InfluxDB::Worker::SLEEP_INTERVAL) do
        queue.pop()
      end
    end

  end


end
