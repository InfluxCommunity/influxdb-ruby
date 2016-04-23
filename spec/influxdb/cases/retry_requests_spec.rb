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

  let(:database) { client.config.database }

  describe "retrying requests" do
    let(:series) { "cpu" }
    let(:data) do
      { tags: { region: 'us', host: 'server_1' },
        values: { temp: 88, value: 54 } }
    end
    let(:body) do
      InfluxDB::PointValue.new(data.merge(series: series)).dump
    end

    subject { client.write_point(series, data) }

    before do
      allow(client).to receive(:log)
      stub_request(:post, "http://influxdb.test:9999/write").with(
        query: { u: "username", p: "password", precision: 's', db: database },
        headers: { "Content-Type" => "application/octet-stream" },
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
        stub_request(:post, "http://influxdb.test:9999/write")
          .with(
            query: { u: "username", p: "password", precision: 's', db: database },
            headers: { "Content-Type" => "application/octet-stream" },
            body: body
          )
          .to_raise(Timeout::Error).then
          .to_raise(Timeout::Error).then
          .to_raise(Timeout::Error).then
          .to_raise(Timeout::Error).then
          .to_return(status: 204)
      end

      it "keep trying until get the connection" do
        expect(client).to receive(:sleep).exactly(4).times
        expect { subject }.to_not raise_error
      end
    end

    it "raise an exception if the server didn't return 200" do
      stub_request(:post, "http://influxdb.test:9999/write").with(
        query: { u: "username", p: "password", precision: 's', db: database },
        headers: { "Content-Type" => "application/octet-stream" },
        body: body
      ).to_return(status: 401)

      expect { client.write_point(series, data) }.to raise_error(InfluxDB::AuthenticationError)
    end
  end
end
