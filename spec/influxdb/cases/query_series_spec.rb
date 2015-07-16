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

  # describe "DELETE #delete_series" do
  #   it "removes a series" do
  #     stub_request(:delete, "http://influxdb.test:9999/db/database/series/foo").with(
  #       query: { u: "username", p: "password" }
  #     )

  #     expect(subject.delete_series("foo")).to be_a(Net::HTTPOK)
  #   end
  # end

  # describe "GET #list_series" do
  #   it "returns a list of all series names" do
  #     data = [
  #       { "name" => "list_series_result",
  #         "columns" => %w(time name),
  #         "points" => [[0, 'a'], [0, 'b']]
  #       }
  #     ]

  #     stub_request(:get, "http://influxdb.test:9999/db/database/series").with(
  #       query: { u: "username", p: "password", q: "list series", time_precision: "s" }
  #     ).to_return(
  #       body: JSON.generate(data)
  #     )

  #     expect(subject.list_series).to eq %w(a b)
  #   end
  # end
end
