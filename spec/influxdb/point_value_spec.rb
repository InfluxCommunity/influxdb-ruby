require "spec_helper"

describe InfluxDB::PointValue do

  describe "whitespace escaping" do
    it 'should escapein series name' do
      point = InfluxDB::PointValue.new(series: "Some Long String", values: {value: 5})
      point.series.should eq("Some\\ Long\\ String")
    end

    it 'should escape keys of passed value keys' do
      point = InfluxDB::PointValue.new(series: "responses",
        values: {'some string key' => 5})
      point.values.split("=").first.should eq("some\\ string\\ key")
    end

    it 'should escape passed values' do
      point = InfluxDB::PointValue.new(series: "responses",
        values: {response_time: 0.34343},
        tags: {city: "Twin Peaks"})
      point.tags.split("=").last.should eq("Twin\\ Peaks")
    end
  end



  describe 'dump' do

    context "with all possible data passed" do
      let(:expected_value) do
        "responses,region=eu,status=200 value=5,threshold=0.54 1436349652"
      end
      it 'should have proper form' do
         point = InfluxDB::PointValue.new(series: "responses",
          values: {value: 5, threshold: 0.54},
          tags: {region: 'eu', status: 200},
          timestamp: 1436349652)

         point.dump.should eq(expected_value)
      end
    end

    context "with no tags" do
      let(:expected_value) do
        "responses value=5,threshold=0.54 1436349652"
      end
      it 'should have proper form' do
         point = InfluxDB::PointValue.new(series: "responses",
          values: {value: 5, threshold: 0.54},
          timestamp: 1436349652)

         point.dump.should eq(expected_value)
      end
    end
    context "with values only" do
      let(:expected_value) do
        "responses value=5,threshold=0.54"
      end
      it 'should have proper form' do
         point = InfluxDB::PointValue.new(series: "responses",
          values: {value: 5, threshold: 0.54})

         point.dump.should eq(expected_value)
      end
    end
  end
end
