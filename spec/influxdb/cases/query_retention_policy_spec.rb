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

  describe "#list_retention_policies" do
    let(:response) { {"results"=>[{"series"=>[{"columns"=>["name","duration","replicaN","default"],"values"=>[["default","0",1,true],["another","1",2,false]]}]}]} }
    let(:expected_result) { [{"name"=>"default","duration"=>"0","replicaN"=>1,"default"=>true},{"name"=>"another","duration"=>"1","replicaN"=>2,"default"=>false}] }

    before do
      stub_request(:get, "http://influxdb.test:9999/query").with(
        query: {u: "username", p: "password", q: "SHOW RETENTION POLICIES \"database\""}
      ).to_return(:body => JSON.generate(response), :status => 200)
    end

    it "should GET a list of retention policies" do
      expect(subject.list_retention_policies('database')).to eq(expected_result)
    end
  end
end
