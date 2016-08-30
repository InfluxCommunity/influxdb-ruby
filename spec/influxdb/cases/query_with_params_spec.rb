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

  describe "#query with parameters" do
    let(:query) { "SELECT value FROM requests_per_minute WHERE time > :start:" }
    let(:query_params) { { start: 1_437_019_900 } }
    let(:query_compiled) { "SELECT value FROM requests_per_minute WHERE time > 1437019900" }

    let(:response) do
      { "results" => [{ "series" => [{ "name" => "requests_per_minute",
                                       "columns" => %w( time value ) }] }] }
    end

    before do
      stub_request(:get, "http://influxdb.test:9999/query")
        .with(query: { db: "database", precision: "s", u: "username", p: "password", q: query_compiled })
        .to_return(body: JSON.generate(response), status: 200)
    end

    it "should handle responses with no values" do
      # Some requests (such as trying to retrieve values from the future)
      # return a result with no "values" key set.
      expected_result = [{ "name" => "requests_per_minute", "tags" => nil, "values" => [] }]
      expect(subject.query(query => query_params)).to eq(expected_result)
    end
  end

  describe "#quote" do
    it "should quote parameters properly" do
      expect(subject.quote(3.14)).to eq('3.14')
      expect(subject.quote(14)).to eq('14')
      expect(subject.quote('3.14')).to eq("'3.14'")
      expect(subject.quote(true)).to eq('true')
      expect(subject.quote(false)).to eq('false')
      expect(subject.quote(0 || 1)).to eq('0')
      expect(subject.quote("Ben Hur's Carriage")).to eq("'Ben Hur\\'s Carriage'")
    end
  end

  describe "#query_builder" do
    let(:query_compiled) { "SELECT value FROM requests_per_minute WHERE time > 1437019900" }
    let(:query_with_named_params) { "SELECT value FROM requests_per_minute WHERE time > :start:" }
    let(:named_params) { { start: 1_437_019_900 } }
    let(:query_with_positional_params) { "SELECT value FROM requests_per_minute WHERE time > :1:" }
    let(:positional_params) { [1_437_019_900] }
    it "should build a query with parameters" do
      expect(subject.query_builder(query_with_named_params => named_params)).to eq(query_compiled)
      expect(subject.query_builder(query_with_positional_params => positional_params)).to eq(query_compiled)
    end
  end
end
