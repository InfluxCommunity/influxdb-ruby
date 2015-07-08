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

  ### TODO ###

  # describe "GET #list_shards" do
  #   it "returns a list of shards" do
  #     shard_list = { "longTerm" => [], "shortTerm" => [] }
  #     stub_request(:get, "http://influxdb.test:9999/cluster/shards").with(
  #       query: { u: "username", p: "password" }
  #     ).to_return(body: JSON.generate(shard_list, status: 200))

  #     expect(subject.list_shards).to eq shard_list
  #   end
  # end

  # describe "DELETE #delete_shard" do
  #   it "removes shard by id" do
  #     shard_id = 1
  #     stub_request(:delete, "http://influxdb.test:9999/cluster/shards/#{shard_id}").with(
  #       query: { u: "username", p: "password" }
  #     )

  #     expect(subject.delete_shard(shard_id, [1, 2])).to be_a(Net::HTTPOK)
  #   end
  # end
end
