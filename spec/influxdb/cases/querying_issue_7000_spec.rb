# This test spec addresses closed issue https://github.com/influxdata/influxdb/issues/7000 where
# it was confirmed that when chunking is enabled, the InfluxDB REST API returns multi-line JSON.

require "spec_helper"
require "json"

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

  let(:args)          { {} }
  let(:database)      { subject.config.database }
  let(:extra_params)  { {} }
  let(:response)      { "" }

  before do
    stub_request(:get, "http://influxdb.test:9999/query")
      .with(query: { q: query, u: "username", p: "password", precision: 's', db: database }.merge(extra_params))
      .to_return(body: response)
  end

  describe "#query" do
    context "with series with different tags (multi-line)" do
      let(:args) { { chunk_size: 100 } }
      let(:extra_params) { { chunked: "true", chunk_size: "100" } }

      let(:response_line_1) do
        { "results" => [{ "series" => [{ "name" => "cpu", "tags" => { "region" => "pl" }, "columns" => %w(time temp value), "values" => [["2015-07-07T15:13:04Z", 34, 0.343443]] }] }] }
      end
      let(:response_line_2) do
        { "results" => [{ "series" => [{ "name" => "cpu", "tags" => { "region" => "us" }, "columns" => %w(time temp value), "values" => [["2015-07-07T14:58:37Z", 92, 0.3445], ["2015-07-07T14:59:09Z", 68, 0.8787]] }] }] }
      end
      let(:response) do
        JSON.generate(response_line_1) + "\n" + JSON.generate(response_line_2)
      end
      let(:expected_result) do
        [{ "name" => "cpu", "tags" => { "region" => "pl" },
           "values" => [{ "time" => "2015-07-07T15:13:04Z", "temp" => 34, "value" => 0.343443 }] },
         { "name" => "cpu", "tags" => { "region" => "us" },
           "values" => [{ "time" => "2015-07-07T14:58:37Z", "temp" => 92, "value" => 0.3445 },
                        { "time" => "2015-07-07T14:59:09Z", "temp" => 68, "value" => 0.8787 }] }]
      end
      let(:query) { 'SELECT * FROM cpu' }

      it "should return array with 2 elements grouped by tags" do
        expect(subject.query(query)).to eq(expected_result)
      end
    end

    context "with multiple series with different tags" do
      let(:args) { { chunk_size: 100 } }
      let(:extra_params) { { chunked: "true", chunk_size: "100" } }

      let(:response_line_1) do
        { "results" => [{ "series" => [{ "name" => "access_times.service_1", "tags" => { "code" => "200", "result" => "failure", "status" => "OK" }, "columns" => %w(time value), "values" => [["2015-07-08T07:15:22Z", 327]] }] }] }
      end
      let(:response_line_2) do
        { "results" => [{ "series" => [{ "name" => "access_times.service_1", "tags" => { "code" => "500", "result" => "failure", "status" => "Internal Server Error" }, "columns" => %w(time value), "values" => [["2015-07-08T06:15:22Z", 873]] }] }] }
      end
      let(:response_line_3) do
        { "results" => [{ "series" => [{ "name" => "access_times.service_2", "tags" => { "code" => "200", "result" => "failure", "status" => "OK" }, "columns" => %w(time value), "values" => [["2015-07-08T07:15:22Z", 943]] }] }] }
      end
      let(:response_line_4) do
        { "results" => [{ "series" => [{ "name" => "access_times.service_2", "tags" => { "code" => "500", "result" => "failure", "status" => "Internal Server Error" }, "columns" => %w(time value), "values" => [["2015-07-08T06:15:22Z", 606]] }] }] }
      end
      let(:response) do
        JSON.generate(response_line_1) + "\n" + JSON.generate(response_line_2) + "\n" + JSON.generate(response_line_3) + "\n" + JSON.generate(response_line_4)
      end
      let(:expected_result) do
        [{ "name" => "access_times.service_1", "tags" => { "code" => "200", "result" => "failure", "status" => "OK" }, "values" => [{ "time" => "2015-07-08T07:15:22Z", "value" => 327 }] },
         { "name" => "access_times.service_1", "tags" => { "code" => "500", "result" => "failure", "status" => "Internal Server Error" }, "values" => [{ "time" => "2015-07-08T06:15:22Z", "value" => 873 }] },
         { "name" => "access_times.service_2", "tags" => { "code" => "200", "result" => "failure", "status" => "OK" }, "values" => [{ "time" => "2015-07-08T07:15:22Z", "value" => 943 }] },
         { "name" => "access_times.service_2", "tags" => { "code" => "500", "result" => "failure", "status" => "Internal Server Error" }, "values" => [{ "time" => "2015-07-08T06:15:22Z", "value" => 606 }] }]
      end
      let(:query) { "SELECT * FROM /access_times.*/" }

      it "should return array with 4 elements grouped by name and tags" do
        expect(subject.query(query)).to eq(expected_result)
      end
    end
  end
end
