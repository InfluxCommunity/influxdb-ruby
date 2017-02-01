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
    let(:query) { "SELECT value FROM requests_per_minute WHERE time > %{start}" }
    let(:query_params) { { start: 1_437_019_900 } }
    let(:query_compiled) { "SELECT value FROM requests_per_minute WHERE time > 1437019900" }

    let(:response) do
      { "results" => [{ "statement_id" => 0,
                        "series" => [{ "name" => "requests_per_minute",
                                       "columns" => %w(time value) }] }] }
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
      expect(subject.query(query, params: query_params)).to eq(expected_result)
    end
  end

  describe "#query_with_params" do
    let(:query)           { "select * from foo where bar > %{param}" }
    let(:compiled_query)  { subject.builder.build(query, query_params) }

    context "with empty params hash" do
      let(:query_params) { {} }
      it { expect { compiled_query }.to raise_error ArgumentError }
    end

    context "with empty params array" do
      let(:query_params) { [] }
      it { expect { compiled_query }.to raise_error ArgumentError }
    end

    context "with empty params" do
      let(:query_params) { nil }
      it { expect { compiled_query }.to raise_error ArgumentError }
    end

    context "with simple params" do
      let(:query_params) { { param: 42 } }
      it { expect(compiled_query).to eq "select * from foo where bar > 42" }
    end

    context "string escaping" do
      let(:query_params) { { param: "string" } }
      it { expect(compiled_query).to eq "select * from foo where bar > 'string'" }
    end
  end
end
