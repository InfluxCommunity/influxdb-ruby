require "spec_helper"

describe InfluxDB::PointValue do

  describe 'load' do

    it 'should raise error if json parsing fails' do
      val = InfluxDB::PointValue.new('{invalid_json')
      val.should_receive(:json?).and_return(true)
      expect { val.load }.to raise_error(InfluxDB::JSONParserError)
    end
  end
end