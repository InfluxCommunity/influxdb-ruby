require "spec_helper"
require "json"

describe InfluxDB::Client do
  let(:subject) do
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

  specify { is_expected.not_to be_stopped }

  context "with basic auth" do
    let(:args) { { auth_method: 'basic_auth' } }

    let(:credentials) { "username:password" }
    let(:auth_header) { { "Authorization" => "Basic " + Base64.encode64(credentials).chomp } }

    let(:stub_url)  { "http://influxdb.test:9999/" }
    let(:url)       { subject.send(:full_url, '/') }

    it "GET" do
      stub_request(:get, stub_url).with(headers: auth_header).to_return(body: '[]')
      expect(subject.get(url, parse: true)).to eq []
    end

    it "POST" do
      stub_request(:post, stub_url).with(headers: auth_header).to_return(status: 204)
      expect(subject.post(url, {})).to be_a(Net::HTTPNoContent)
    end
  end

  describe "#full_url" do
    it "returns String" do
      expect(subject.send(:full_url, "/unknown")).to be_a String
    end

    it "escapes params" do
      url = subject.send(:full_url, "/unknown", value: ' !@#$%^&*()/\\_+-=?|`~')
      expect(url).to include("value=+%21%40%23%24%25%5E%26%2A%28%29%2F%5C_%2B-%3D%3F%7C%60%7E")
    end

    context "with prefix" do
      let(:args) { { prefix: '/dev' } }

      it "returns path with prefix" do
        expect(subject.send(:full_url, "/series")).to start_with("/dev")
      end
    end
  end

  describe "GET #ping" do
    it "returns OK" do
      stub_request(:get, "http://influxdb.test:9999/ping")
        .to_return(status: 204)

      expect(subject.ping).to be_a(Net::HTTPNoContent)
    end

    context "with prefix" do
      let(:args) { { prefix: '/dev' } }

      it "returns OK with prefix" do
        stub_request(:get, "http://influxdb.test:9999/dev/ping")
          .to_return(status: 204)

        expect(subject.ping).to be_a(Net::HTTPNoContent)
      end
    end
  end

  describe "GET #version" do
    it "returns 1.1.1" do
      stub_request(:get, "http://influxdb.test:9999/ping")
        .to_return(status: 204, headers: { 'x-influxdb-version' => '1.1.1' })

      expect(subject.version).to eq('1.1.1')
    end

    context "with prefix" do
      let(:args) { { prefix: '/dev' } }

      it "returns 1.1.1 with prefix" do
        stub_request(:get, "http://influxdb.test:9999/dev/ping")
          .to_return(status: 204, headers: { 'x-influxdb-version' => '1.1.1' })

        expect(subject.version).to eq('1.1.1')
      end
    end
  end

  describe "Load balancing" do
    let(:args) { { hosts: hosts } }
    let(:hosts) do
      [
        "influxdb.test0",
        "influxdb.test1",
        "influxdb.test2"
      ]
    end
    let(:cycle) { 3 }
    let!(:stubs) do
      hosts.map { |host| stub_request(:get, "http://#{host}:9999/ping").to_return(status: 204) }
    end

    it "balance requests" do
      (hosts.size * cycle).times { subject.ping }
      stubs.cycle(cycle) { |stub| expect(stub).to have_been_requested.times(cycle) }
    end
  end
end
