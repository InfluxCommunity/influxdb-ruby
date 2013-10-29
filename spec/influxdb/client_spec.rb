require "spec_helper"
require "json"

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
    it "should POST to create a new database" do
      stub_request(:post, "http://influxdb.test:9999/db").with(
        :query => {:u => "username", :p => "password"},
        :body => JSON.generate({:name => "foo"})
      )

      @influxdb.create_database("foo").should be_a(Net::HTTPOK)
    end
  end

  describe "#delete_database" do
    it "should DELETE to remove a database" do
      stub_request(:delete, "http://influxdb.test:9999/db/foo").with(
        :query => {:u => "username", :p => "password"}
      )

      @influxdb.delete_database("foo").should be_a(Net::HTTPOK)
    end
  end


  describe "#write_point" do
    it "should POST to add points" do
      body = {
        :name => "seriez",
        :points => [["juan", 87]],
        :columns => ["name", "age"]
      }

      stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
        :query => {:u => "username", :p => "password"},
        :body => JSON.generate(body)
      )

      # data = [{:name => "juan", :age => 87}, {:name => "pablo", :age => 64}]
      data = {:name => "juan", :age => 87}

      @influxdb.write_point("seriez", data).should be_a(Net::HTTPOK)
    end
  end
end
