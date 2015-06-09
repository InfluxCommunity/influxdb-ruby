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

  describe "POST #create_database" do
    it "creates a new database" do
      stub_request(:post, "http://influxdb.test:9999/db").with(
        query: { u: "username", p: "password" },
        body: { name: "foo" }
      )

      expect(subject.create_database("foo")).to be_a(Net::HTTPOK)
    end
  end

  describe "DELETE #delete_database" do
    it "removes a database" do
      stub_request(:delete, "http://influxdb.test:9999/db/foo").with(
        query: { u: "username", p: "password" }
      )

      expect(subject.delete_database("foo")).to be_a(Net::HTTPOK)
    end
  end

  describe "GET #list_databases" do
    it "returns a list of databases" do
      database_list = [{ "name" => "foobar" }]
      stub_request(:get, "http://influxdb.test:9999/db").with(
        query: { u: "username", p: "password" }
      ).to_return(body: JSON.generate(database_list), status: 200)

      expect(subject.list_databases).to eq database_list
    end
  end
end
