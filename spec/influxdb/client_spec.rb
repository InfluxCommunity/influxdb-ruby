require "spec_helper"

describe InfluxDB::Client do
  describe "#new" do
    it "should instantiate a new InfluxDB client" do
      influxdb = InfluxDB::Client.new("host", "port", "username", "password", "database")

      influxdb.should be_a(InfluxDB::Client)
    end
  end
end
