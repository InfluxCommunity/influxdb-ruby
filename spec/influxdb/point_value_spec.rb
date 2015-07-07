require "spec_helper"

describe InfluxDB::PointValue do
  describe '#load' do
    it 'parses json as array' do
      val = described_class.new('["foo", "bar"]')
      expect(val.load).to eq %w(foo bar)
    end

    it 'parses json as hash' do
      val = described_class.new('{"foo":"bar"}')
      expect(val.load).to eq("foo" => "bar")
    end

    it 'return string value if invalid json array' do
      val = described_class.new('[foo,bar]')
      expect(val.load).to eq '[foo,bar]'
    end

    it 'return string value if invalid json hash' do
      val = described_class.new('{foo:"bar"}')
      expect(val.load).to eq '{foo:"bar"}'
    end
  end
end
