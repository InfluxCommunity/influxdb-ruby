require "spec_helper"
require "json"

describe InfluxDB::UDPClient do
  subject { described_class.new("localhost", 44444) }
  let(:message) { "responses,region=eu value=5" }

  describe "#send" do
    it "sends a UPD packet" do
      s = UDPSocket.new
      s.bind("localhost", 44444)
      subject.send(message)

      rec_message = s.recvfrom(30).first
      expect(rec_message).to eq message
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
