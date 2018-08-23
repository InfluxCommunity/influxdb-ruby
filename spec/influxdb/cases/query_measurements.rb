require "spec_helper"
require "json"

describe InfluxDB::Client do
  let(:subject) do
    described_class.new \
      database:       "database",
      host:           "influxdb.test",
      port:           9999,
      username:       "username",
      password:       "password",
      time_precision: "s"
  end

  let(:query) { nil }
  let(:response) { { "results" => [{ "statement_id" => 0 }] } }

  before do
    stub_request(:get, "http://influxdb.test:9999/query")
      .with(query: { u: "username", p: "password", q: query })
      .to_return(body: JSON.generate(response))
  end

  describe "#list_measuremtns" do
    let(:query) { "SHOW MEASUREMENTS" }

    context "with measurements" do
      let(:response) { { "results" => [{ "statement_id" => 0, "series" => [{ "columns" => "name", "values" => [["average_temperature"], ["h2o_feet"], ["h2o_pH"], ["h2o_quality"], ["h2o_temperature"]] }] }] } }
      let(:expected_result) { %w[average_temperature h2o_feet h2o_pH h2o_quality h2o_temperature] }

      it "should GET a list of measurements" do
        expect(subject.list_measurements).to eq(expected_result)
      end
    end

    context "without measurements" do
      let(:response) { { "results" => [{ "statement_id" => 0 }] } }
      let(:expected_result) { nil }

      it "should GET a list of measurements" do
        expect(subject.list_measurements).to eq(expected_result)
      end
    end
  end

  describe "#delete_retention_policy" do
    let(:query) { "DROP MEASUREMENT \"foo\"" }

    it "should GET to remove a database" do
      expect(subject.delete_measurement('foo')).to be true
    end
  end
end
