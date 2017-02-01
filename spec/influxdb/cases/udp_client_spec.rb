require "spec_helper"

describe InfluxDB::Client do
  let(:client) { described_class.new(udp: { host: "localhost", port: 44_444 }) }

  specify { expect(client.writer).to be_a(InfluxDB::Writer::UDP) }

  describe "#write" do
    let(:message) { 'responses,region=eu value=5i' }

    it "sends a UDP packet" do
      s = UDPSocket.new
      s.bind("localhost", 44_444)

      client.write_point("responses", values: { value: 5 }, tags: { region: 'eu' })

      rec_message = s.recvfrom(30).first
      expect(rec_message).to eq message

      s.close
    end
  end

  describe "#write with discard_write_errors" do
    let(:client) do
      described_class.new(
        udp: { host: "localhost", port: 44_444 },
        discard_write_errors: true
      )
    end

    it "doesn't raise" do
      s = UDPSocket.new
      s.bind("localhost", 44_444)

      client.write_point("responses", values: { value: 5 }, tags: { region: 'eu' })
      s.close

      client.write_point("responses", values: { value: 7 }, tags: { region: 'eu' })

      allow(client).to receive(:log)
      expect do
        client.write_point("responses", values: { value: 7 }, tags: { region: 'eu' })
      end.not_to raise_error
    end
  end
end
