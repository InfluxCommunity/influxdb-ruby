require "spec_helper"

describe InfluxDB::Client do
  let(:client) { described_class.new(udp: { host: "localhost", port: 44_444 }) }

  specify { expect(client.writer).to be_a(InfluxDB::Writer::UDP) }

  describe "#write" do
    let(:message) { 'responses,region=eu value=5' }

    it "sends a UPD packet" do
      s = UDPSocket.new
      s.bind("localhost", 44_444)

      client.write_point("responses", values: { value: 5 }, tags: { region: 'eu' })

      rec_message = s.recvfrom(30).first
      expect(rec_message).to eq message
    end
  end
end
