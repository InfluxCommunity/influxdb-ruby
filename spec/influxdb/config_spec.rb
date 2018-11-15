require 'spec_helper'

describe InfluxDB::Config do
  let(:conf) do
    InfluxDB::Client.new(*args).config
  end

  let(:args) { {} }

  context "with no parameters specified" do
    specify { expect(conf.database).to be_nil }
    specify { expect(conf.hosts).to eq ["localhost"] }
    specify { expect(conf.port).to eq 8086 }
    specify { expect(conf.username).to eq "root" }
    specify { expect(conf.password).to eq "root" }
    specify { expect(conf.use_ssl).to be_falsey }
    specify { expect(conf.time_precision).to eq "s" }
    specify { expect(conf.auth_method).to eq "params" }
    specify { expect(conf.denormalize).to be_truthy }
    specify { expect(conf).not_to be_udp }
    specify { expect(conf).not_to be_async }
    specify { expect(conf.epoch).to be_falsey }
  end

  context "with no database specified" do
    let(:args) do
      [{
        host:           "host",
        port:           "port",
        username:       "username",
        password:       "password",
        time_precision: "m"
      }]
    end

    specify { expect(conf.database).to be_nil }
    specify { expect(conf.hosts).to eq ["host"] }
    specify { expect(conf.port).to eq "port" }
    specify { expect(conf.username).to eq "username" }
    specify { expect(conf.password).to eq "password" }
    specify { expect(conf.time_precision).to eq "m" }
    specify { expect(conf.epoch).to be_falsey }
  end

  context "with both a database and options specified" do
    let(:args) do
      [
        "database",
        host:           "host",
        port:           "port",
        username:       "username",
        password:       "password",
        time_precision: "m"
      ]
    end

    specify { expect(conf.database).to eq "database" }
    specify { expect(conf.hosts).to eq ["host"] }
    specify { expect(conf.port).to eq "port" }
    specify { expect(conf.username).to eq "username" }
    specify { expect(conf.password).to eq "password" }
    specify { expect(conf.time_precision).to eq "m" }
    specify { expect(conf.epoch).to be_falsey }
  end

  context "with ssl option specified" do
    let(:args) { [{ use_ssl: true }] }

    specify { expect(conf.database).to be_nil }
    specify { expect(conf.hosts).to eq ["localhost"] }
    specify { expect(conf.port).to eq 8086 }
    specify { expect(conf.username).to eq "root" }
    specify { expect(conf.password).to eq "root" }
    specify { expect(conf.use_ssl).to be_truthy }
  end

  context "with multiple hosts specified" do
    let(:args) { [{ hosts: ["1.1.1.1", "2.2.2.2"] }] }

    specify { expect(conf.database).to be_nil }
    specify { expect(conf.port).to eq 8086 }
    specify { expect(conf.username).to eq "root" }
    specify { expect(conf.password).to eq "root" }
    specify { expect(conf.hosts).to eq ["1.1.1.1", "2.2.2.2"] }
  end

  context "with auth_method basic auth specified" do
    let(:args) { [{ auth_method: 'basic_auth' }] }

    specify { expect(conf.database).to be_nil }
    specify { expect(conf.hosts).to eq ["localhost"] }
    specify { expect(conf.port).to eq 8086 }
    specify { expect(conf.username).to eq "root" }
    specify { expect(conf.password).to eq "root" }
    specify { expect(conf.auth_method).to eq "basic_auth" }
  end

  context "with udp specified with params" do
    let(:args) { [{ udp: { host: 'localhost', port: 4444 } }] }

    specify { expect(conf).to be_udp }
  end

  context "with udp specified as true" do
    let(:args) { [{ udp: true }] }

    specify { expect(conf).to be_udp }
  end

  context "with async specified with params" do
    let(:args) { [{ async: { max_queue: 20_000 } }] }

    specify { expect(conf).to be_async }
  end

  context "with async specified as true" do
    let(:args) { [{ async: true }] }

    specify { expect(conf).to be_async }
  end

  context "with epoch specified as seconds" do
    let(:args) { [{ epoch: 's' }] }

    specify { expect(conf.epoch).to eq 's' }
  end

  context "given a config URL" do
    let(:url) { "https://foo:bar@influx.example.com:8765/testdb?open_timeout=42&unknown=false&denormalize=false" }
    let(:args) { [{ url: url }] }

    it "applies values found in URL" do
      expect(conf.database).to eq "testdb"
      expect(conf.hosts).to eq ["influx.example.com"]
      expect(conf.port).to eq 8765
      expect(conf.username).to eq "foo"
      expect(conf.password).to eq "bar"
      expect(conf.use_ssl).to be true
      expect(conf.denormalize).to be false
      expect(conf.open_timeout).to eq 42
    end

    it "applies defaults" do
      expect(conf.prefix).to eq ""
      expect(conf.read_timeout).to be 300
      expect(conf.max_delay).to be 30
      expect(conf.initial_delay).to be_within(0.0001).of(0.01)
      expect(conf.verify_ssl).to be true
      expect(conf.ssl_ca_cert).to be false
      expect(conf.epoch).to be false
      expect(conf.discard_write_errors).to be false
      expect(conf.retry).to be(-1)
      expect(conf.chunk_size).to be nil
      expect(conf).not_to be_udp
      expect(conf.auth_method).to eq "params"
      expect(conf).not_to be_async
    end

    context "UDP" do
      let(:url) { "udp://test.localhost:2345?discard_write_errors=1" }
      specify { expect(conf).to be_udp }
      specify { expect(conf.udp[:port]).to be 2345 }
      specify { expect(conf.discard_write_errors).to be true }
    end
  end

  context "given a config URL and explicit options" do
    let(:url) { "https://foo:bar@influx.example.com:8765/testdb?open_timeout=42&unknown=false&denormalize=false" }
    let(:args) do
      [
        "primarydb",
        url:          url,
        open_timeout: 20,
        read_timeout: 30,
      ]
    end

    it "applies values found in URL" do
      expect(conf.hosts).to eq ["influx.example.com"]
      expect(conf.port).to eq 8765
      expect(conf.username).to eq "foo"
      expect(conf.password).to eq "bar"
      expect(conf.use_ssl).to be true
      expect(conf.denormalize).to be false
    end

    it "applies values found in opts hash" do
      expect(conf.database).to eq "primarydb"
      expect(conf.open_timeout).to eq 20
      expect(conf.read_timeout).to be 30
    end

    it "applies defaults" do
      expect(conf.prefix).to eq ""
      expect(conf.max_delay).to be 30
      expect(conf.initial_delay).to be_within(0.0001).of(0.01)
      expect(conf.verify_ssl).to be true
      expect(conf.ssl_ca_cert).to be false
      expect(conf.epoch).to be false
      expect(conf.discard_write_errors).to be false
      expect(conf.retry).to be(-1)
      expect(conf.chunk_size).to be nil
      expect(conf).not_to be_udp
      expect(conf.auth_method).to eq "params"
      expect(conf).not_to be_async
    end
  end
end
