require "spec_helper"

RSpec.describe InfluxDB do
  describe ".convert_timestamp" do
    let(:sometime) { Time.parse("2017-12-11 16:20:29.111222333 UTC") }

    {
      "ns" => 1_513_009_229_111_222_333,
      nil  => 1_513_009_229_111_222_333,
      "u"  => 1_513_009_229_111_222,
      "ms" => 1_513_009_229_111,
      "s"  => 1_513_009_229,
      "m"  => 25_216_820,
      "h"  => 420_280,
    }.each do |precision, converted_value|
      it "should return the timestamp in #{precision.inspect}" do
        expect(described_class.convert_timestamp(sometime, precision)).to eq(converted_value)
      end
    end

    it "should raise an excpetion when precision is unrecognized" do
      expect { described_class.convert_timestamp(sometime, "whatever") }
        .to raise_exception(/invalid time precision.*whatever/i)
    end
  end
end
