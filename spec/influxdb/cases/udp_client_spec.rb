require "spec_helper"

describe InfluxDB::Client do
  let(:client) { described_class.new(udp: { host: "localhost", port: 44_444 }) }

  specify { expect(client.writer).to be_a(InfluxDB::Writer::UDP) }

  describe "#write" do
    let(:message) { [{ "name" => "foo", "points" => [[1]], "columns" => ['a'] }] }

    it "sends a UPD packet" do
      s = UDPSocket.new
      s.bind("localhost", 44_444)

      client.write_point("foo", a: 1)

      rec_mesage = JSON.parse(s.recvfrom(47).first)
      expect(rec_mesage).to eq message
    end
  end
end
