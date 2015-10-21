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
        host: "host",
        port: "port",
        username: "username",
        password: "password",
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
        host: "host",
        port: "port",
        username: "username",
        password: "password",
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
end
