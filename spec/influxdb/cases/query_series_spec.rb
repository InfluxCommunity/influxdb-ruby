require "spec_helper"
require "json"

describe InfluxDB::Client do
  let(:subject) do
    described_class.new(
      "database",
      {
        host: "influxdb.test",
        port: 9999,
        username: "username",
        password: "password",
        time_precision: "s"
      }.merge(args)
    )
  end

  let(:args) { {} }

  describe "GET #list_series" do
    let(:response) { { "results" => [{ "series" => [{ "columns" => "key", "values" => [["series1,name=default,duration=0"], ["series2,name=another,duration=1"]] }] }] } }
    let(:data) { %w(series1 series2) }
    let(:query) { "SHOW SERIES" }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: { u: "username", p: "password", q: query, db: "database" }
      ).to_return(
        body: JSON.generate(response)
      )
    end

    it "returns a list of all series names" do
      expect(subject.list_series).to eq data
    end
  end

  describe "#delete_series" do
    let(:name) { "events" }
    let(:query) { "DROP SERIES FROM #{name}" }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: { u: "username", p: "password", q: query, db: "database" }
      )
    end

    it "should GET to remove a database" do
      expect(subject.delete_series(name)).to be_a(Net::HTTPOK)
    end
  end
end
