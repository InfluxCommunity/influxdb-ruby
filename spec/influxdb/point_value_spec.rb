require "spec_helper"

describe InfluxDB::PointValue do

  describe 'load' do

    it 'should parse json as array' do
      val = InfluxDB::PointValue.new('["foo", "bar"]')
      val.load.should == %w(foo bar)
    end

    it 'should parse json as hash' do
      val = InfluxDB::PointValue.new('{"foo":"bar"}')
      val.load.should == {"foo" => "bar"}
    end

    it 'should return string value if invalid json array' do
      val = InfluxDB::PointValue.new('[foo,bar]')
      val.load.should == '[foo,bar]'
    end

    it 'should return string value if invalid json hash' do
      val = InfluxDB::PointValue.new('{foo:"bar"}')
      val.load.should == '{foo:"bar"}'
    end
  end
end