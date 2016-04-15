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
                                       "columns" => %w( time value ) }] }] }
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
end
