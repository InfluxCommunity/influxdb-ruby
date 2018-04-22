require "spec_helper"

describe InfluxDB::Client, smoke: true do
  before do
    WebMock.allow_net_connect!
  end

  after do
    WebMock.disable_net_connect!
  end

  let(:client) do
    InfluxDB::Client.new \
      database: "NOAA_water_database",
      username: "test_user",
      password: "resu_tset",
      retry:    4
  end

  context "connects to the database" do
    it "returns the version number" do
      expect(client.version).to be_truthy
    end
  end

  context "retrieves data from the NOAA database" do
    sample_data1 = {
      "time"              => "2015-08-18T00:00:00Z",
      "level description" => "below 3 feet",
      "location"          => "santa_monica",
      "water_level"       => 2.064
    }

    sample_data2 = {
      "time"              => "2015-08-18T00:12:00Z",
      "level description" => "below 3 feet",
      "location"          => "santa_monica",
      "water_level"       => 2.028
    }

    it "returns all five measurements" do
      result = client.query("show measurements")[0]["values"].map { |v| v["name"] }
      expect(result).to eq(%w[average_temperature h2o_feet h2o_pH h2o_quality h2o_temperature])
    end

    it "counts the number of non-null values of water level in h2o feet" do
      result = client.query("select count(water_level) from h2o_feet")[0]["values"][0]["count"]
      expect(result).to eq(15_258)
    end

    it "selects the first five observations in the measurement h2o_feet" do
      result = client
               .query("select * from h2o_feet WHERE location = 'santa_monica'")
               .first["values"]
      expect(result.size). to eq(7654)
      expect(result).to include(sample_data1)
      expect(result).to include(sample_data2)
    end
  end

  context "batch query" do
    let :queries do
      [
        "select count(water_level) from h2o_feet where location = 'santa_monica'",
        "select * from h2o_feet where time > now()", # empty result
        "select count(water_level) from h2o_feet where location = 'coyote_creek'",
      ]
    end

    it "#query filters empty results incorrect result" do
      results = client.query(queries.join(";"))
      expect(results.size).to be 2 # but should be 3!
      expect(results[0]["values"][0]["count"]).to be 7654
      expect(results[1]["values"][0]["count"]).to be 7604
    end
  end
end
