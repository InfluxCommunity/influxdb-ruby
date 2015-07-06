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

  specify { is_expected.not_to be_stopped }

  context "with basic auth" do
    let(:args) { { auth_method: 'basic_auth' } }

    let(:stub_url) { "http://username:password@influxdb.test:9999/" }
    let(:url) { subject.send(:full_url, '/') }

    it "GET" do
      stub_request(:get, stub_url).to_return(body: '[]')
      expect(subject.get(url)).to eq []
    end

    it "POST" do
      stub_request(:post, stub_url)
      expect(subject.post(url, {})).to be_a(Net::HTTPOK)
    end

    it "DELETE" do
      stub_request(:delete, stub_url)
      expect(subject.delete(url, {})).to be_a(Net::HTTPOK)
    end
  end

  describe "#full_url" do
    it "returns String" do
      expect(subject.send(:full_url, "/unknown")).to be_a String
    end

    it "escapes params" do
      url = subject.send(:full_url, "/unknown", value: ' !@#$%^&*()/\\_+-=?|`~')
      expect(url).to include("value=+%21%40%23%24%25%5E%26%2A%28%29%2F%5C_%2B-%3D%3F%7C%60%7E")
    end
  end

  describe "#query" do
    describe "GET #ping" do
      it "returns OK" do
        status_ok = { "status" => "ok" }
        stub_request(:get, "http://influxdb.test:9999/ping")
          .to_return(body: JSON.generate(status_ok), status: 200)

        expect(subject.ping).to eq status_ok
      end
    end

    context "execute queries" do
      before(:each) do
        data = [{
          name: "foo",
          columns: %w(name age count count),
          points: [["shahid", 99, 1, 2], ["dix", 50, 3, 4]]
        }]

        stub_request(:get, "http://influxdb.test:9999/db/database/series").with(
          query: { q: "select * from foo", u: "username", p: "password", time_precision: "s" }
        ).to_return(
          body: JSON.generate(data)
        )
      end

      let(:expected_series) do
        {
          'foo' => [
            { "name" => "shahid", "age" => 99, "count" => 1, "count~1" => 2 },
            { "name" => "dix", "age" => 50, "count" => 3, "count~1" => 4 }
          ]
        }
      end

      it 'with a block' do
        series = {}

        subject.query "select * from foo" do |name, points|
          series[name] = points
        end

        expect(series).to eq expected_series
      end

      it 'without a block' do
        series = subject.query 'select * from foo'
        expect(series).to eq expected_series
      end
    end

    it 'loads JSON point value as an array of hashes' do
      line_items = [{ 'id' => 1, 'product_id' => 2, 'quantity' => 1, 'price' => "100.00" }]

      data = [{ name: "orders", columns: %w(id line_items), points: [[1, line_items.to_json]] }]

      stub_request(:get, "http://influxdb.test:9999/db/database/series").with(
        query: { q: "select * from orders", u: "username", p: "password", time_precision: "s" }
      ).to_return(
        body: JSON.generate(data)
      )

      expect(subject.query('select * from orders'))
        .to eq('orders' => [{ 'id' => 1, 'line_items' => line_items }])
    end

    it 'returns raw result with denormalize false' do
      data = [{ "name" => "orders", "columns" => %w(id cpu), "points" => [[1, 80]] }]

      stub_request(:get, "http://influxdb.test:9999/db/database/series").with(
        query: { q: "select * from orders", u: "username", p: "password", time_precision: "s" }
      ).to_return(
        body: JSON.generate(data)
      )

      expect(subject.query('select * from orders', denormalize: false))
        .to eq(data)
    end

    it 'series not found' do
      stub_request(:get, "http://influxdb.test:9999/db/database/series").with(
        query: { q: "select * from orders", u: "username", p: "password", time_precision: "s" }
      ).to_return(
        body: "Couldn't find series: orders",
        status: 400
      )

      expect { subject.query('select * from orders') }.to raise_error(InfluxDB::SeriesNotFound)
    end
  end
end
