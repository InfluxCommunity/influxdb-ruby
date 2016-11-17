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

  let(:args) { {} }

  let(:database) { subject.config.database }

  describe "#write_point" do
    let(:series) { "cpu" }
    let(:data) do
      { tags: { region: 'us', host: 'server_1' },
        values: { temp: 88, value: 54 } }
    end
    let(:body) do
      InfluxDB::PointValue.new(data.merge(series: series)).dump
    end

    before do
      stub_request(:post, "http://influxdb.test:9999/write").with(
        query: { u: "username", p: "password", precision: 's', db: database },
        headers: { "Content-Type" => "application/octet-stream" },
        body: body
      ).to_return(status: 204)
    end

    it "should POST to add single point" do
      expect(subject.write_point(series, data)).to be_a(Net::HTTPNoContent)
    end

    it "should not mutate data object" do
      original_data = data
      subject.write_point(series, data)
      expect(data[:series]).to be_nil
      expect(original_data).to eql(data)
    end
  end

  describe "#write_points" do
    context "with multiple series" do
      let(:data) do
        [{ series: 'cpu',
           tags: { region: 'us', host: 'server_1' },
           values: { temp: 88, value: 54 } },
         { series: 'gpu',
           tags: { region: 'uk', host: 'server_5' },
           values: { value: 0.5435345 } }]
      end
      let(:body) do
        data.map do |point|
          InfluxDB::PointValue.new(point).dump
        end.join("\n")
      end

      before do
        stub_request(:post, "http://influxdb.test:9999/write").with(
          query: { u: "username", p: "password", precision: 's', db: database },
          headers: { "Content-Type" => "application/octet-stream" },
          body: body
        ).to_return(status: 204)
      end

      it "should POST multiple points" do
        expect(subject.write_points(data)).to be_a(Net::HTTPNoContent)
      end
    end

    context "with no tags" do
      let(:data) do
        [{ series: 'cpu',
           values: { temp: 88, value: 54 } },
         { series: 'gpu',
           values: { value: 0.5435345 } }]
      end
      let(:body) do
        data.map do |point|
          InfluxDB::PointValue.new(point).dump
        end.join("\n")
      end

      before do
        stub_request(:post, "http://influxdb.test:9999/write").with(
          query: { u: "username", p: "password", precision: 's', db: database },
          headers: { "Content-Type" => "application/octet-stream" },
          body: body
        ).to_return(status: 204)
      end

      it "should POST multiple points" do
        expect(subject.write_points(data)).to be_a(Net::HTTPNoContent)
      end
    end

    context "with time precision set to milisceconds" do
      let(:data) do
        [{ series: 'cpu',
           values: { temp: 88, value: 54 },
           timestamp: (Time.now.to_f * 1000).to_i },
         { series: 'gpu',
           values: { value: 0.5435345 },
           timestamp: (Time.now.to_f * 1000).to_i }]
      end

      let(:body) do
        data.map do |point|
          InfluxDB::PointValue.new(point).dump
        end.join("\n")
      end

      before do
        stub_request(:post, "http://influxdb.test:9999/write").with(
          query: { u: "username", p: "password", precision: 'ms', db: database },
          headers: { "Content-Type" => "application/octet-stream" },
          body: body
        ).to_return(status: 204)
      end
      it "should POST multiple points" do
        expect(subject.write_points(data, 'ms')).to be_a(Net::HTTPNoContent)
      end
    end

    context "with retention policy" do
      let(:data) do
        [{ series: 'cpu',
           values: { temp: 88, value: 54 } },
         { series: 'gpu',
           values: { value: 0.5435345 } }]
      end

      let(:body) do
        data.map do |point|
          InfluxDB::PointValue.new(point).dump
        end.join("\n")
      end

      before do
        stub_request(:post, "http://influxdb.test:9999/write").with(
          query: { u: "username", p: "password", precision: 's', db: database, rp: 'rp_1_hour' },
          headers: { "Content-Type" => "application/octet-stream" },
          body: body
        ).to_return(status: 204)
      end
      it "should POST multiple points" do
        expect(subject.write_points(data, nil, 'rp_1_hour')).to be_a(Net::HTTPNoContent)
      end
    end

    context "with database" do
      let(:data) do
        [{ series: 'cpu',
           values: { temp: 88, value: 54 } },
         { series: 'gpu',
           values: { value: 0.5435345 } }]
      end

      let(:body) do
        data.map do |point|
          InfluxDB::PointValue.new(point).dump
        end.join("\n")
      end

      before do
        stub_request(:post, "http://influxdb.test:9999/write").with(
          query: { u: "username", p: "password", precision: 's', db: 'overriden_db' },
          headers: { "Content-Type" => "application/octet-stream" },
          body: body
        ).to_return(status: 204)
      end
      it "should POST multiple points" do
        expect(subject.write_points(data, nil, nil, 'overriden_db')).to be_a(Net::HTTPNoContent)
      end
    end
  end
end
