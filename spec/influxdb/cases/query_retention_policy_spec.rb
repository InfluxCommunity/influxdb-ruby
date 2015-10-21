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

  describe "#list_retention_policies" do
    let(:response) { { "results" => [{ "series" => [{ "columns" => %w(name duration replicaN default), "values" => [["default", "0", 1, true], ["another", "1", 2, false]] }] }] } }
    let(:expected_result) { [{ "name" => "default", "duration" => "0", "replicaN" => 1, "default" => true }, { "name" => "another", "duration" => "1", "replicaN" => 2, "default" => false }] }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: { u: "username", p: "password", q: "SHOW RETENTION POLICIES ON \"database\"" }
      ).to_return(body: JSON.generate(response), status: 200)
    end

    it "should GET a list of retention policies" do
      expect(subject.list_retention_policies('database')).to eq(expected_result)
    end
  end

  describe "#create_retention_policy" do
    context "default" do
      before do
        stub_request(:get, "http://influxdb.test:9999/query")
          .with(
            query:
              {
                u: "username",
                p: "password",
                q: "CREATE RETENTION POLICY \"1h.cpu\" ON foo DURATION 1h REPLICATION 2 DEFAULT"
              }
          )
      end

      it "should GET to create a new database" do
        expect(subject.create_retention_policy('1h.cpu', 'foo', '1h', 2, true)).to be_a(Net::HTTPOK)
      end
    end

    context "non-default" do
      before do
        stub_request(:get, "http://influxdb.test:9999/query")
          .with(
            query:
              {
                u: "username",
                p: "password",
                q: "CREATE RETENTION POLICY \"1h.cpu\" ON foo DURATION 1h REPLICATION 2"
              }
          )
      end

      it "should GET to create a new database" do
        expect(subject.create_retention_policy('1h.cpu', 'foo', '1h', 2)).to be_a(Net::HTTPOK)
      end
    end
  end

  describe "#delete_retention_policy" do
    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: { u: "username", p: "password", q: "DROP RETENTION POLICY \"1h.cpu\" ON foo" }
      )
    end

    it "should GET to remove a database" do
      expect(subject.delete_retention_policy('1h.cpu', 'foo')).to be_a(Net::HTTPOK)
    end
  end

  describe "#alter_retention_policy" do
    context "default" do
      before do
        stub_request(:get, "http://influxdb.test:9999/query")
          .with(
            query:
              {
                u: "username",
                p: "password",
                q: "ALTER RETENTION POLICY \"1h.cpu\" ON foo DURATION 1h REPLICATION 2 DEFAULT"
              }
          )
      end

      it "should GET to alter a new database" do
        expect(subject.alter_retention_policy('1h.cpu', 'foo', '1h', 2, true)).to be_a(Net::HTTPOK)
      end
    end

    context "non-default" do
      before do
        stub_request(:get, "http://influxdb.test:9999/query")
          .with(
            query:
              {
                u: "username",
                p: "password",
                q: "ALTER RETENTION POLICY \"1h.cpu\" ON foo DURATION 1h REPLICATION 2"
              }
          )
      end

      it "should GET to alter a new database" do
        expect(subject.alter_retention_policy('1h.cpu', 'foo', '1h', 2)).to be_a(Net::HTTPOK)
      end
    end
  end
end
