require "spec_helper"
require "json"

describe InfluxDB::UDPClient do
  subject { described_class.new("localhost", 44444) }
  let(:message) { [{ "foo" => "bar" }] }

  describe "#send" do
    it "sends a UPD packet" do
      s = UDPSocket.new
      s.bind("localhost", 44444)
      subject.send(message)
      rec_mesage = JSON.parse(s.recvfrom(15).first)
      expect(rec_mesage).to eq message
    end

    context "it can't connect" do
      before do
        subject.socket = FailingSocket.new
      end

      it "doesn't blow up" do
        expect { subject.send(message) }.to_not raise_error
      end
    end

    class FailingSocket < UDPSocket
      def send(*args)
        fail
      end
    end
  end
end
