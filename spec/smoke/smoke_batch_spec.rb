require "spec_helper"

describe InfluxDB::Client, smoke: true, if: min_influx_version("1.2.0") do
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

  context "#batch.execute" do
    it "returns expected results" do
      results = client.batch do |b|
        queries.each { |q| b.add(q) }
      end.execute

      expect(results.size).to be 3
      expect(results[0][0]["values"][0]["count"]).to be 7654
      expect(results[1]).to eq []
      expect(results[2][0]["values"][0]["count"]).to be 7604
    end

    it "with block yields statement id" do
      batch = client.batch do |b|
        queries.each { |q| b.add(q) }
      end

      batch.execute do |sid, _, _, values|
        case sid
        when 0
          expect(values[0]["count"]).to be 7654
        when 1
          expect(values).to eq []
        when 2
          expect(values[0]["count"]).to be 7604
        end
      end
    end

    context "with tags" do
      let :queries do
        [
          "select count(water_level) from h2o_feet group by location",
          "select * from h2o_feet where time > now()", # empty result
        ]
      end

      it "returns expected results" do
        results = client.batch do |b|
          queries.each { |q| b.add(q) }
        end.execute

        expect(results.size).to be 2
        results[0].each do |res|
          location = res["tags"]["location"]
          expect(%w[coyote_creek santa_monica]).to include location

          value = location == "santa_monica" ? 7654 : 7604
          expect(res["values"][0]["count"]).to be value
        end
      end

      it "with block yields statement id" do
        batch = client.batch do |b|
          queries.each { |q| b.add(q) }
        end

        got_santa_monica = got_coyote_creek = got_empty_result = false

        batch.execute do |sid, _, tags, values|
          case [sid, tags["location"]]
          when [0, "santa_monica"]
            expect(values[0]["count"]).to be 7654
            got_santa_monica = true
          when [0, "coyote_creek"]
            expect(values[0]["count"]).to be 7604
            got_coyote_creek = true
          when [1, nil]
            expect(values).to eq []
            got_empty_result = true
          end
        end

        expect(got_coyote_creek).to be true
        expect(got_santa_monica).to be true
        expect(got_empty_result).to be true
      end
    end
  end
end
