require "spec_helper"

describe InfluxDB::Client do
  let(:subject) do
    described_class.new "database", {
      host: "influxdb.test",
      port: 9999,
      username: "username",
      password: "password",
      time_precision: "s"
    }.merge(args)
  end

  let(:args) { {} }

  describe "#query" do
    let(:query) { "SELECT value FROM requests_per_minute WHERE time > 1437019900" }
    let(:response) do
      { "results" => [{ "series" => [{ "name" => "requests_per_minute",
                                       "columns" => %w(time value) }] }] }
    end

    before do
      stub_request(:get, "http://influxdb.test:9999/query")
        .with(query: { db: "database", precision: "s", u: "username", p: "password", q: query })
        .to_return(body: JSON.generate(response), status: 200)
    end

    it "should handle responses with no values" do
      # Some requests (such as trying to retrieve values from the future)
      # return a result with no "values" key set.
      expected_result = [{ "name" => "requests_per_minute", "tags" => nil, "values" => [] }]
      expect(subject.query(query)).to eq(expected_result)
    end
  end

  describe "#fetch_series" do
    let(:response) do
      { "results" => [{ "series" => [{ "name" => "requests_per_minute",
                                       "columns" => %w(time value) }] }] }
    end

    it "should fetch series" do
      expect(subject.send(:fetch_series, response)[0]['name']).to eq('requests_per_minute')
      expect(subject.send(:fetch_series, response)[0]['columns']).to eq(%w(time value))
    end
  end

  describe "#denormalize_series" do
    let(:series) do
      { "columns" => %w(name duration replicaN default), "values" => [["default", "0", 1, true], ["another", "1", 2, false]] }
    end

    it "should denormalize series" do
      expect(subject.send(:denormalize_series, series)).to eq([Hash["name", "default", "duration", "0", "replicaN", 1, "default", true],
                                                               Hash["name", "another", "duration", "1", "replicaN", 2, "default", false]])
    end
  end

  describe "#denormalized_series_list" do
    let(:series) do
      [{ "name" => "requests_per_minute", "columns" => %w(name duration replicaN default),
         "tags" => { region: "pl" },
         "values" => [["default", "0", 1, true], ["another", "1", 2, false]] },
       { "name" => "cpu", "columns" => %w(time temp value),
         "tags" => { region: "us" },
         "values" => [["2015-07-07T15:13:04Z", 34, 0.343443], ["2015-07-08T14:13:04Z", 35, 0.32222]] }]
    end

    it "should denormalize series list" do
      expect(subject.send(:denormalized_series_list, series)[0]['name']).to eq('requests_per_minute')
      expect(subject.send(:denormalized_series_list, series)[0]['tags']).to eq(region: "pl")
      expect(subject.send(:denormalized_series_list, series)[0]['values']).to eq([Hash["name", "default", "duration", "0", "replicaN", 1, "default", true],
                                                                                  Hash["name", "another", "duration", "1", "replicaN", 2, "default", false]])
      expect(subject.send(:denormalized_series_list, series)[1]['name']).to eq('cpu')
      expect(subject.send(:denormalized_series_list, series)[1]['tags']).to eq(region: "us")
      expect(subject.send(:denormalized_series_list, series)[1]['values']).to eq([Hash["time", "2015-07-07T15:13:04Z", "temp", 34, "value", 0.343443],
                                                                                  Hash["time", "2015-07-08T14:13:04Z", "temp", 35, "value", 0.32222]])
    end
  end
end
