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
  let(:response)      {}

  before do
    stub_request(:get, "http://influxdb.test:9999/query")
      .with(query: { q: query, u: "username", p: "password", precision: 's', db: database }.merge(extra_params))
      .to_return(body: JSON.generate(response))
  end

  describe "#query" do
    context "with single series with multiple points" do
      let(:response) do
        { "results" => [{ "series" => [{ "name" => "cpu", "tags" => { "region" => "us" },
                                         "columns" => %w(time temp value),
                                         "values" => [["2015-07-07T14:58:37Z", 92, 0.3445], ["2015-07-07T14:59:09Z", 68, 0.8787]] }] }] }
      end
      let(:expected_result) do
        [{ "name" => "cpu", "tags" => { "region" => "us" },
           "values" => [{ "time" => "2015-07-07T14:58:37Z", "temp" => 92, "value" => 0.3445 },
                        { "time" => "2015-07-07T14:59:09Z", "temp" => 68, "value" => 0.8787 }] }]
      end
      let(:query) { 'SELECT * FROM cpu' }

      it "should return array with single hash containing multiple values" do
        expect(subject.query(query)).to eq(expected_result)
      end
    end

    context "with series with different tags" do
      let(:response) do
        { "results" => [{ "series" => [{ "name" => "cpu", "tags" => { "region" => "pl" }, "columns" => %w(time temp value), "values" => [["2015-07-07T15:13:04Z", 34, 0.343443]] },
                                       { "name" => "cpu", "tags" => { "region" => "us" }, "columns" => %w(time temp value), "values" => [["2015-07-07T14:58:37Z", 92, 0.3445], ["2015-07-07T14:59:09Z", 68, 0.8787]] }] }] }
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
      let(:response) do
        { "results" => [{ "series" => [{ "name" => "access_times.service_1", "tags" => { "code" => "200", "result" => "failure", "status" => "OK" }, "columns" => %w(time value), "values" => [["2015-07-08T07:15:22Z", 327]] },
                                       { "name" => "access_times.service_1", "tags" => { "code" => "500", "result" => "failure", "status" => "Internal Server Error" }, "columns" => %w(time value), "values" => [["2015-07-08T06:15:22Z", 873]] },
                                       { "name" => "access_times.service_2", "tags" => { "code" => "200", "result" => "failure", "status" => "OK" }, "columns" => %w(time value), "values" => [["2015-07-08T07:15:22Z", 943]] },
                                       { "name" => "access_times.service_2", "tags" => { "code" => "500", "result" => "failure", "status" => "Internal Server Error" }, "columns" => %w(time value), "values" => [["2015-07-08T06:15:22Z", 606]] }] }] }
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

    context "with multiple series for explicit value only" do
      let(:response) do
        { "results" => [{ "series" => [{ "name" => "access_times.service_1", "columns" => %w(time value), "values" => [["2015-07-08T06:15:22Z", 873], ["2015-07-08T07:15:22Z", 327]] },
                                       { "name" => "access_times.service_2", "columns" => %w(time value), "values" => [["2015-07-08T06:15:22Z", 606], ["2015-07-08T07:15:22Z", 943]] }] }] }
      end
      let(:expected_result) do
        [{ "name" => "access_times.service_1", "tags" => nil, "values" => [{ "time" => "2015-07-08T06:15:22Z", "value" => 873 }, { "time" => "2015-07-08T07:15:22Z", "value" => 327 }] },
         { "name" => "access_times.service_2", "tags" => nil, "values" => [{ "time" => "2015-07-08T06:15:22Z", "value" => 606 }, { "time" => "2015-07-08T07:15:22Z", "value" => 943 }] }]
      end
      let(:query) { "SELECT value FROM /access_times.*/" }

      it "should return array with 2 elements grouped by name only and no tags" do
        expect(subject.query(query)).to eq(expected_result)
      end
    end

    context "with a block" do
      let(:response) do
        { "results" => [{ "series" => [{ "name" => "cpu", "tags" => { "region" => "pl" }, "columns" => %w(time temp value), "values" => [["2015-07-07T15:13:04Z", 34, 0.343443]] },
                                       { "name" => "cpu", "tags" => { "region" => "us" }, "columns" => %w(time temp value), "values" => [["2015-07-07T14:58:37Z", 92, 0.3445], ["2015-07-07T14:59:09Z", 68, 0.8787]] }] }] }
      end

      let(:expected_result) do
        [{ "name" => "cpu", "tags" => { "region" => "pl" },
           "values" => [{ "time" => "2015-07-07T15:13:04Z", "temp" => 34, "value" => 0.343443 }] },
         { "name" => "cpu", "tags" => { "region" => "us" },
           "values" => [{ "time" => "2015-07-07T14:58:37Z", "temp" => 92, "value" => 0.3445 },
                        { "time" => "2015-07-07T14:59:09Z", "temp" => 68, "value" => 0.8787 }] }]
      end
      let(:query) { 'SELECT * FROM cpu' }

      it "should accept a block and yield name, tags and points" do
        results = []
        subject.query(query) do |name, tags, points|
          results << { 'name' => name, 'tags' => tags, 'values' => points }
        end
        expect(results).to eq(expected_result)
      end
    end

    context "with epoch set to seconds" do
      let(:args) { { epoch: 's' } }
      let(:extra_params) { { epoch: 's' } }

      let(:response) do
        { "results" => [{ "series" => [{ "name" => "cpu", "tags" => { "region" => "pl" }, "columns" => %w(time temp value), "values" => [[1_438_580_576, 34, 0.343443]] },
                                       { "name" => "cpu", "tags" => { "region" => "us" }, "columns" => %w(time temp value), "values" => [[1_438_612_976, 92, 0.3445], [1_438_612_989, 68, 0.8787]] }] }] }
      end
      let(:expected_result) do
        [{ "name" => "cpu", "tags" => { "region" => "pl" },
           "values" => [{ "time" => 1_438_580_576, "temp" => 34, "value" => 0.343443 }] },
         { "name" => "cpu", "tags" => { "region" => "us" },
           "values" => [{ "time" => 1_438_612_976, "temp" => 92, "value" => 0.3445 },
                        { "time" => 1_438_612_989, "temp" => 68, "value" => 0.8787 }] }]
      end
      let(:query) { 'SELECT * FROM cpu' }

      it "should return results with integer timestamp" do
        expect(subject.query(query)).to eq(expected_result)
      end
    end

    context "with chunk_size set to 100" do
      let(:args) { { chunk_size: 100 } }
      let(:extra_params) { { chunked: "true", chunk_size: "100" } }

      let(:response) do
        { "results" => [{ "series" => [{ "name" => "cpu", "tags" => { "region" => "pl" }, "columns" => %w(time temp value), "values" => [[1_438_580_576, 34, 0.343443]] }] }] }
      end
      let(:expected_result) do
        [{ "name" => "cpu", "tags" => { "region" => "pl" }, "values" => [{ "time" => 1_438_580_576, "temp" => 34, "value" => 0.343443 }] }]
      end
      let(:query) { 'SELECT * FROM cpu' }

      it "should set 'chunked' and 'chunk_size' parameters" do
        expect(subject.query(query)).to eq(expected_result)
      end
    end
  end

  describe "multiple select queries" do
    context "with single series with multiple points" do
      let(:response) do
        { "results" => [{ "series" => [{ "name" => "cpu", "tags" => { "region" => "us" },
                                         "columns" => %w(time temp value),
                                         "values" => [["2015-07-07T14:58:37Z", 92, 0.3445], ["2015-07-07T14:59:09Z", 68, 0.8787]] }] },
                        { "series" => [{ "name" => "memory", "tags" => { "region" => "us" },
                                         "columns" => %w(time free total),
                                         "values" => [["2015-07-07T14:58:37Z", 96_468_992, 134_217_728], ["2015-07-07T14:59:09Z", 71_303_168, 134_217_728]] }] }] }
      end
      let(:expected_result) do
        [{ "name" => "cpu", "tags" => { "region" => "us" },
           "values" => [{ "time" => "2015-07-07T14:58:37Z", "temp" => 92, "value" => 0.3445 },
                        { "time" => "2015-07-07T14:59:09Z", "temp" => 68, "value" => 0.8787 }] },
         { "name" => "memory", "tags" => { "region" => "us" },
           "values" => [{ "time" => "2015-07-07T14:58:37Z", "free" => 92 * 2**20, "total" => 128 * 2**20 },
                        { "time" => "2015-07-07T14:59:09Z", "free" => 68 * 2**20, "total" => 128 * 2**20 }] }]
      end
      let(:query) { 'SELECT * FROM cpu; SELECT * FROM memory' }

      it "should return array with single hash containing multiple values" do
        expect(subject.query(query)).to eq(expected_result)
      end
    end

    context "with series with different tags" do
      let(:response) do
        { "results" => [{ "series" => [{ "name" => "cpu", "tags" => { "region" => "pl" }, "columns" => %w(time temp value), "values" => [["2015-07-07T15:13:04Z", 34, 0.343443]] },
                                       { "name" => "cpu", "tags" => { "region" => "us" }, "columns" => %w(time temp value), "values" => [["2015-07-07T14:58:37Z", 92, 0.3445], ["2015-07-07T14:59:09Z", 68, 0.8787]] }] },
                        { "series" => [{ "name" => "memory", "tags" => { "region" => "pl" }, "columns" => %w(time free total), "values" => [["2015-07-07T15:13:04Z", 35_651_584, 134_217_728]] },
                                       { "name" => "memory", "tags" => { "region" => "us" }, "columns" => %w(time free total), "values" => [["2015-07-07T14:58:37Z", 96_468_992, 134_217_728], ["2015-07-07T14:59:09Z", 71_303_168, 134_217_728]] }] }] }
      end
      let(:expected_result) do
        [{ "name" => "cpu", "tags" => { "region" => "pl" },
           "values" => [{ "time" => "2015-07-07T15:13:04Z", "temp" => 34, "value" => 0.343443 }] },
         { "name" => "cpu", "tags" => { "region" => "us" },
           "values" => [{ "time" => "2015-07-07T14:58:37Z", "temp" => 92, "value" => 0.3445 },
                        { "time" => "2015-07-07T14:59:09Z", "temp" => 68, "value" => 0.8787 }] },
         { "name" => "memory", "tags" => { "region" => "pl" },
           "values" => [{ "time" => "2015-07-07T15:13:04Z", "free" => 34 * 2**20, "total" => 128 * 2**20 }] },
         { "name" => "memory", "tags" => { "region" => "us" },
           "values" => [{ "time" => "2015-07-07T14:58:37Z", "free" => 92 * 2**20, "total" => 128 * 2**20 },
                        { "time" => "2015-07-07T14:59:09Z", "free" => 68 * 2**20, "total" => 128 * 2**20 }] }]
      end
      let(:query) { 'SELECT * FROM cpu; SELECT * FROM memory' }

      it "should return array with 2 elements grouped by tags" do
        expect(subject.query(query)).to eq(expected_result)
      end
    end

    context "with a block" do
      let(:response) do
        { "results" => [{ "series" => [{ "name" => "cpu", "tags" => { "region" => "pl" }, "columns" => %w(time temp value), "values" => [["2015-07-07T15:13:04Z", 34, 0.343443]] },
                                       { "name" => "cpu", "tags" => { "region" => "us" }, "columns" => %w(time temp value), "values" => [["2015-07-07T14:58:37Z", 92, 0.3445], ["2015-07-07T14:59:09Z", 68, 0.8787]] }] },
                        { "series" => [{ "name" => "memory", "tags" => { "region" => "pl" }, "columns" => %w(time free total), "values" => [["2015-07-07T15:13:04Z", 35_651_584, 134_217_728]] },
                                       { "name" => "memory", "tags" => { "region" => "us" }, "columns" => %w(time free total), "values" => [["2015-07-07T14:58:37Z", 96_468_992, 134_217_728], ["2015-07-07T14:59:09Z", 71_303_168, 134_217_728]] }] }] }
      end

      let(:expected_result) do
        [{ "name" => "cpu", "tags" => { "region" => "pl" },
           "values" => [{ "time" => "2015-07-07T15:13:04Z", "temp" => 34, "value" => 0.343443 }] },
         { "name" => "cpu", "tags" => { "region" => "us" },
           "values" => [{ "time" => "2015-07-07T14:58:37Z", "temp" => 92, "value" => 0.3445 },
                        { "time" => "2015-07-07T14:59:09Z", "temp" => 68, "value" => 0.8787 }] },
         { "name" => "memory", "tags" => { "region" => "pl" },
           "values" => [{ "time" => "2015-07-07T15:13:04Z", "free" => 34 * 2**20, "total" => 128 * 2**20 }] },
         { "name" => "memory", "tags" => { "region" => "us" },
           "values" => [{ "time" => "2015-07-07T14:58:37Z", "free" => 92 * 2**20, "total" => 128 * 2**20 },
                        { "time" => "2015-07-07T14:59:09Z", "free" => 68 * 2**20, "total" => 128 * 2**20 }] }]
      end
      let(:query) { 'SELECT * FROM cpu; SELECT * FROM memory' }

      it "should accept a block and yield name, tags and points" do
        results = []
        subject.query(query) do |name, tags, points|
          results << { 'name' => name, 'tags' => tags, 'values' => points }
        end
        expect(results).to eq(expected_result)
      end
    end
  end
end
