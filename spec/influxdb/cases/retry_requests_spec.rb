require "spec_helper"
require "json"

describe InfluxDB::Client do
  let(:client) do
    described_class.new(
      "database",
      {
        host: "influxdb.test",
        port: 9999,
        username: "username",
        password: "password",
        time_precision: "s"
      }.merge(args)
    )
  end

  let(:args) { {} }

  describe "retrying requests" do
    let(:body) do
      [{
        "name" => "seriez",
        "points" => [[87, "juan"]],
        "columns" => %w(age name)
      }]
    end

    let(:data) { { name: "juan", age: 87 } }

    subject { client.write_point("seriez", data) }

    before do
      allow(client).to receive(:log)
      stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
        query: { u: "username", p: "password", time_precision: "s" },
        body: body
      ).to_raise(Timeout::Error)
    end

    it "raises when stopped" do
      client.stop!
      expect(client).not_to receive(:sleep)
      expect { subject }.to raise_error(InfluxDB::ConnectionError) do |e|
        expect(e.cause).to be_an_instance_of(Timeout::Error)
      end
    end

    context "when retry is 0" do
      let(:args) { { retry: 0 } }
      it "raise error directly" do
        expect(client).not_to receive(:sleep)
        expect { subject }.to raise_error(InfluxDB::ConnectionError) do |e|
          expect(e.cause).to be_an_instance_of(Timeout::Error)
        end
      end
    end

    context "when retry is 'n'" do
      let(:args) { { retry: 3 } }

      it "raise error after 'n' attemps" do
        expect(client).to receive(:sleep).exactly(3).times
        expect { subject }.to raise_error(InfluxDB::ConnectionError) do |e|
          expect(e.cause).to be_an_instance_of(Timeout::Error)
        end
      end
    end

    context "when retry is -1" do
      let(:args) { { retry: -1 } }
      before do
        stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
          query: { u: "username", p: "password", time_precision: "s" },
          body: body
        ).to_raise(Timeout::Error).then
          .to_raise(Timeout::Error).then
          .to_raise(Timeout::Error).then
          .to_raise(Timeout::Error).then
          .to_return(status: 200)
      end

      it "keep trying until get the connection" do
        expect(client).to receive(:sleep).exactly(4).times
        expect { subject }.to_not raise_error
      end
    end
  end
end
