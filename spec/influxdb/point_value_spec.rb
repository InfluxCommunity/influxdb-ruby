# encoding: UTF-8

require "spec_helper"
require "date"

describe InfluxDB::PointValue do
  describe "escaping" do
    let(:data) do
      point = {
        series: '1= ,"\\1',
        tags: {
          '2= ,"\\2' => '3= ,"\\3'
        },
        values: {
          '4= ,"\\4' => '5= ,"\\5',
          intval:           5,
          floatval:         7.0,
          invalid_encoding: "a b",
          non_latin:        "Улан-Удэ"
        }
      }
      if RUBY_VERSION > "2.0.0"
        # see github.com/influxdata/influxdb-ruby/issues/171 for details
        point[:values][:invalid_encoding] = "a\255 b"
      end
      point
    end

    it 'should escape correctly' do
      point = InfluxDB::PointValue.new(data)
      expected = %(1=\\ \\,"\\1,2\\=\\ \\,"\\2=3\\=\\ \\,"\\3 ) +
                 %(4\\=\\ \\,\\"\\4="5= ,\\"\\5",intval=5i,floatval=7.0,invalid_encoding="a b",non_latin="Улан-Удэ")
      expect(point.dump).to eq(expected)
    end
  end

  describe "timestamp escaping" do
    let(:timestamp) { nil }
    let(:precision) { nil }
    let(:data) do
      point = {
        series:     "responses",
        tags:       { reg: :eu },
        values:     { v: 5 },
      }
      point[:timestamp] = timestamp if timestamp
      point
    end

    subject { InfluxDB::PointValue.new(data, precision: precision).dump }

    context "default behaviour" do
      subject { InfluxDB::PointValue.new(data).dump }
      it { is_expected.to eq "responses,reg=eu v=5i" }
    end

    context "no precision" do
      context "given a numeric value" do
        let(:timestamp) { 1234 }
        it { is_expected.to eq "responses,reg=eu v=5i 1234" }
      end

      context "given a Time value" do
        let(:timestamp) { Time.at(1234.5) }
        it { is_expected.to eq "responses,reg=eu v=5i 1234500000000" }
      end

      context "given a Date value" do
        let(:timestamp) { Date.new(2017, 4, 13) }
        it { is_expected.to eq "responses,reg=eu v=5i 1492034400000000000" }
      end

      context "given a DateTime value" do
        let(:timestamp) { DateTime.new(2017, 4, 13, 12, 52, 7.0005) }
        it { is_expected.to eq "responses,reg=eu v=5i 1492087927000500000" }
      end
    end

    context "given second precision" do
      let(:precision) { "s" }

      context "given a numeric value" do
        let(:timestamp) { 1234 }
        it { is_expected.to eq "responses,reg=eu v=5i 1234" }
      end

      context "given a Time value" do
        let(:timestamp) { Time.at(1234.56) }
        it { is_expected.to eq "responses,reg=eu v=5i 1234" }
      end

      context "given a Date value" do
        let(:timestamp) { Date.new(2017, 4, 13) }
        it { is_expected.to eq "responses,reg=eu v=5i 1492034400" }
      end

      context "given a DateTime value" do
        let(:timestamp) { DateTime.new(2017, 4, 13, 12, 52, 7.0005) }
        it { is_expected.to eq "responses,reg=eu v=5i 1492087927" }
      end
    end

    context "given hour precision" do
      let(:precision) { "h" }

      context "a numeric value doesn't change" do
        let(:timestamp) { 1234 }
        it { is_expected.to eq "responses,reg=eu v=5i 1234" }
      end

      context "given a Time value" do
        let(:timestamp) { Time.at(7200.56) }
        it { is_expected.to eq "responses,reg=eu v=5i 2" }
      end

      context "given a Date value" do
        let(:timestamp) { Date.new(2017, 4, 13) }
        it { is_expected.to eq "responses,reg=eu v=5i 414454" }
      end

      context "given a DateTime value" do
        let(:timestamp) { DateTime.new(2017, 4, 13, 12, 52, 7.0005) }
        it { is_expected.to eq "responses,reg=eu v=5i 414468" }
      end
    end
  end

  describe 'dump' do
    context "with all possible data passed" do
      let(:expected_value) do
        'responses,region=eu,status=200 value=5i,threshold=0.54 1436349652'
      end
      it 'should have proper form' do
        point = InfluxDB::PointValue.new \
          series:     "responses",
          values:     { value: 5, threshold: 0.54 },
          tags:       { region: 'eu', status: 200 },
          timestamp:  1_436_349_652

        expect(point.dump).to eq(expected_value)
      end
    end

    context "without tags" do
      let(:expected_value) do
        "responses value=5i,threshold=0.54 1436349652"
      end
      it 'should have proper form' do
        point = InfluxDB::PointValue.new \
          series:     "responses",
          values:     { value: 5, threshold: 0.54 },
          timestamp:  1_436_349_652

        expect(point.dump).to eq(expected_value)
      end
    end

    context "without tags and timestamp" do
      let(:expected_value) do
        "responses value=5i,threshold=0.54"
      end
      it 'should have proper form' do
        point = InfluxDB::PointValue.new \
          series: "responses",
          values: { value: 5, threshold: 0.54 }

        expect(point.dump).to eq(expected_value)
      end
    end

    context "empty tag values" do
      let(:expected_value) do
        "responses,region=eu value=5i"
      end

      it "should be omitted" do
        point = InfluxDB::PointValue.new \
          series: "responses",
          values: { value: 5 },
          tags:   { region: "eu", status: nil, other: "", nil => "ignored", "" => "ignored" }
        expect(point.dump).to eq(expected_value)
      end
    end
  end
end
