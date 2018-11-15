require "spec_helper"
require "json"

describe InfluxDB::Client do
  let(:subject) do
    described_class.new \
      database: "database",
      host:     "influxdb.test",
      port:     9999,
      username: "username",
      password: "password"
  end

  let(:query) { nil }
  let(:response) { { "results" => [{ "statement_id" => 0 }] } }

  before do
    stub_request(:get, "http://influxdb.test:9999/query")
      .with(query: { u: "username", p: "password", q: query, db: "database" })
      .to_return(body: JSON.generate(response))
  end

  describe "#show_field_keys" do
    let(:query) { "SHOW FIELD KEYS" }
    let(:response) do
      {
        "results" => [{
          "series" => [{
            "name"    => "measurement_a",
            "columns" => %w[fieldKey fieldType],
            "values"  => [%w[a_string_field string],
                          %w[a_boolean_field boolean],
                          %w[a_float_field float],
                          %w[an_integer_field integer]]
          }, {
            "name"    => "measurement_b",
            "columns" => %w[fieldKey fieldType],
            "values"  => [%w[another_string string]]
          }]
        }]
      }
    end
    let(:expected_result) do
      {
        "measurement_a" => {
          "a_string_field"   => ["string"],
          "a_boolean_field"  => ["boolean"],
          "a_float_field"    => ["float"],
          "an_integer_field" => ["integer"],
        },
        "measurement_b" => {
          "another_string" => ["string"],
        }
      }
    end

    it "should GET a list of field/type pairs per measurement" do
      expect(subject.show_field_keys).to eq(expected_result)
    end
  end
end
