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

  describe "#write_point" do
    let(:body) do
      [{
        "name" => "seriez",
        "points" => [[87, "juan"]],
        "columns" => %w(age name)
      }]
    end

    let(:data) { { name: "juan", age: 87 } }

    before do
      stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
        query: { u: "username", p: "password", time_precision: "s" },
        body: body
      ).to_return(status: 200)
    end

    it "add points" do
      expect(subject.write_point("seriez", data)).to be_a(Net::HTTPOK)
    end

    it "raise an exception if the server didn't return 200" do
      stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
        query: { u: "username", p: "password", time_precision: "s" },
        body: body
      ).to_return(status: 401)

      expect { subject.write_point("seriez", data) }.to raise_error
    end

    context "multiple points" do
      let(:body) do
        [{
          "name" => "seriez",
          "points" => [[87, "juan"], [99, "shahid"]],
          "columns" => %w(age name)
        }]
      end

      let(:data) do
        [
          { name: "juan", age: 87 },
          { name: "shahid", age: 99 }
        ]
      end

      specify { expect(subject.write_point("seriez", data)).to be_a(Net::HTTPOK) }
    end

    context "multiple points with missing columns" do
      let(:body) do
        [{
          "name" => "seriez",
          "points" => [[87, "juan"], [nil, "shahid"]],
          "columns" => %w(age name)
        }]
      end

      let(:data) { [{ name: "juan", age: 87 }, { name: "shahid" }] }

      specify { expect(subject.write_point("seriez", data)).to be_a(Net::HTTPOK) }
    end

    context "multiple series" do
      let(:body) do
        [
          {
            "name" => "seriez",
            "points" => [[87, "juan"]],
            "columns" => %w(age name)
          },
          {
            "name" => "seriez_2",
            "points" => [[nil, "jack"], [true, "john"]],
            "columns" => %w(active name)
          }
        ]
      end

      let(:data) do
        [
          { name: "seriez", data: { name: "juan", age: 87 } },
          { name: "seriez_2", data: [{ name: "jack" }, { name: "john", active: true }] }
        ]
      end

      specify { expect(subject.write_points(data)).to be_a(Net::HTTPOK) }
    end

    context "data dump" do
      it "dumps a hash point value to json" do
        prefs = [{ 'favorite_food' => 'lasagna' }]
        body = [{
          "name" => "users",
          "points" => [[1, prefs.to_json]],
          "columns" => %w(id prefs)
        }]

        stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
          query: { u: "username", p: "password", time_precision: "s" },
          body: body
        )

        data = { id: 1, prefs: prefs }

        expect(subject.write_point("users", data)).to be_a(Net::HTTPOK)
      end

      it "dumps an array point value to json" do
        line_items = [{ 'id' => 1, 'product_id' => 2, 'quantity' => 1, 'price' => "100.00" }]

        body = [{
          "name" => "seriez",
          "points" => [[1, line_items.to_json]],
          "columns" => %w(id line_items)
        }]

        stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
          query: { u: "username", p: "password", time_precision: "s" },
          body: body
        )

        data = { id: 1, line_items: line_items }

        expect(subject.write_point("seriez", data)).to be_a(Net::HTTPOK)
      end
    end

    context "time precision" do
      it "add points with time field with precision defined in client initialization" do
        time_in_seconds = Time.now.to_i
        body = [{
          "name" => "seriez",
          "points" => [[87, "juan", time_in_seconds]],
          "columns" => %w(age name time)
        }]

        stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
          query: { u: "username", p: "password", time_precision: "s" },
          body: body
        )

        data = { name: "juan", age: 87, time: time_in_seconds }

        expect(subject.write_point("seriez", data)).to be_a(Net::HTTPOK)
      end

      it "add points with time field with precision defined in config" do
        time_in_milliseconds = (Time.now.to_f * 1000).to_i
        body = [{
          "name" => "seriez",
          "points" => [[87, "juan", time_in_milliseconds]],
          "columns" => %w(age name time)
        }]

        stub_request(:post, "http://influxdb.test:9999/db/database/series").with(
          query: { u: "username", p: "password", time_precision: "m" },
          body: body
        )

        data = { name: "juan", age: 87, time: time_in_milliseconds }

        subject.config.time_precision = "m"

        expect(subject.write_point("seriez", data))
          .to be_a(Net::HTTPOK)
      end
    end
  end
end
