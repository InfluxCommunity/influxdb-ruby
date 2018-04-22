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
      { "results" => [{ "statement_id" => 0,
                        "series" => [{ "name" => "requests_per_minute",
                                       "columns" => %w[time value] }] }] }
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

  describe '#batched_query' do
    context "with multiple queries when there is no data for a query" do
      let(:queries) {[
        "SELECT value FROM requests_per_minute WHERE time > 1437019900;",
        "SELECT value FROM requests_per_minute WHERE time > now();",
        "SELECT value FROM requests_per_minute WHERE time > 1437019900;",
      ]}
      let(:response) do
        { "results" => [
          {"statement_id"=>0, "series"=> [{
            "name"=>"requests_per_minute",
            "columns"=>["time", "value"],
            "values"=> [["2018-04-02T00:00:00Z", "204"]]
          }]},
          {"statement_id"=>1},
          {"statement_id"=>2, "series"=> [{
            "name"=>"requests_per_minute",
            "columns"=>["time", "value"],
            "values"=> [["2018-04-02T00:00:00Z", "204"]]
          }]}]
        }
      end

      before do
        stub_request(:get, "http://influxdb.test:9999/query")
          .with(query: { db: "database", precision: "s", u: "username", p: "password", q: queries.join('') })
          .to_return(body: JSON.generate(response), status: 200)
      end

      it "should return responses for all statements" do
        batched_result = subject.batched_query(queries: queries)
        expect(batched_result.length).to eq(response['results'].length)
        expect(batched_result).to eq([
          [{
            "name"=>"requests_per_minute",
            "tags"=>nil,
            "values"=> [{"time" => "2018-04-02T00:00:00Z", "value" => "204"}],
          }],
          [],
          [{
            "name"=>"requests_per_minute",
            "tags"=>nil,
            "values"=> [{"time" => "2018-04-02T00:00:00Z", "value" => "204"}],
          }],
        ])
      end
    end

    context "with a group by tag query" do
      let(:queries) { ["SELECT value FROM requests_per_minute WHERE time > now() - 1d GROUP BY status_code;"] }
      let(:response) do
        { "results" => [
          {"statement_id"=>0, "series"=> [
            {
              "name"=>"requests_per_minute",
              "tags"=>{ "status_code" => "200" },
              "columns"=>["time", "value"],
              "values"=> [["2018-04-02T00:00:00Z", "204"]]
            }, {
              "name"=>"requests_per_minute",
              "tags"=>{ "status_code" => "500" },
              "columns"=>["time", "value"],
              "values"=> [["2018-04-02T00:00:00Z", "204"]]
            }
          ]}
        ]}
      end

      before do
        stub_request(:get, "http://influxdb.test:9999/query")
          .with(query: { db: "database", precision: "s", u: "username", p: "password", q: queries.join('') })
          .to_return(body: JSON.generate(response), status: 200)
      end

      it "should return a single result" do
        batched_result = subject.batched_query(queries: queries)
        expect(batched_result.length).to eq(response['results'].length)
        expect(batched_result).to eq([[
          {
            "name"=>"requests_per_minute",
            "tags"=>{ "status_code" => "200" },
            "values"=> [{"time" => "2018-04-02T00:00:00Z", "value" => "204"}],
          }, {
            "name"=>"requests_per_minute",
            "tags"=>{ "status_code" => "500" },
            "values"=> [{"time" => "2018-04-02T00:00:00Z", "value" => "204"}],
          }
        ]])
      end
    end
  end
end
