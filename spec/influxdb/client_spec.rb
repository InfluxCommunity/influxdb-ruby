require "spec_helper"

describe InfluxDB::Client do
  before do
    @influxdb = InfluxDB::Client.new("influxdb.test", 9999, "username", "password", "database")
  end

  describe "#new" do
    it "should instantiate a new InfluxDB client" do
      @influxdb = InfluxDB::Client.new("host", "port", "username", "password", "database")

      @influxdb.should be_a(InfluxDB::Client)
    end
  end

  describe "#create_database" do
    it "should POST to create a new database with the proper credentials" do
      stub_request(:post, "http://influxdb.test:9999/db").with(
        :query => {:u => "username", :p => "password"},
        :body => %q{{"name": "foo"}}
      )

      @influxdb.create_database("foo").should be_a(Net::HTTPOK)
    end
  end

  describe "#delete_database" do
    it "should DELETE to remove a database with the proper credentials" do
      stub_request(:delete, "http://influxdb.test:9999/db/foo").with(
        :query => {:u => "username", :p => "password"}
      )

      @influxdb.delete_database("foo").should be_a(Net::HTTPOK)
    end
  end
end
