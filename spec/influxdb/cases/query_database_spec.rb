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
  let(:query) { nil }
  let(:response) { { "results" => [{ "statement_id" => 0 }] } }

  before do
    stub_request(:get, "http://influxdb.test:9999/query").with(
      query: { u: "username", p: "password", q: query }
    ).to_return(body: JSON.generate(response))
  end

  describe "#create_database" do
    describe "from param" do
      let(:query) { "CREATE DATABASE foo" }

      it "should GET to create a new database" do
        expect(subject.create_database("foo")).to be_a(Net::HTTPOK)
      end
    end

    describe "from config" do
      let(:query) { "CREATE DATABASE database" }

      it "should GET to create a new database using database name from config" do
        expect(subject.create_database).to be_a(Net::HTTPOK)
      end
    end
  end

  describe "#delete_database" do
    describe "from param" do
      let(:query) { "DROP DATABASE foo" }

      it "should GET to remove a database" do
        expect(subject.delete_database("foo")).to be_a(Net::HTTPOK)
      end
    end

    describe "from config" do
      let(:query) { "DROP DATABASE database" }

      it "should GET to remove a database using database name from config" do
        expect(subject.delete_database).to be_a(Net::HTTPOK)
      end
    end
  end

  describe "#list_databases" do
    let(:query) { "SHOW DATABASES" }
    let(:response) { { "results" => [{ "series" => [{ "name" => "databases", "columns" => ["name"], "values" => [["foobar"]] }] }] } }
    let(:expected_result) { [{ "name" => "foobar" }] }

    it "should GET a list of databases" do
      expect(subject.list_databases).to eq(expected_result)
    end
  end
end
