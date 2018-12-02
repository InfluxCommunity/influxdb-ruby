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

  describe ".now" do
    {
      "ns" => [:nanosecond,   1_513_009_229_111_222_333],
      nil  => [:nanosecond,   1_513_009_229_111_222_333],
      "u"  => [:microsecond,  1_513_009_229_111_222],
      "ms" => [:millisecond,  1_513_009_229_111],
      "s"  => [:second,       1_513_009_229],
      "m"  => [:second,       25_216_820,   1_513_009_229],
      "h"  => [:second,       420_280,      1_513_009_229],
    }.each do |precision, (name, expected, stub)|
      it "should return the current time in #{precision.inspect}" do
        expect(Process).to receive(:clock_gettime)
          .with(Process::CLOCK_REALTIME, name)
          .and_return(stub || expected)
        expect(described_class.now(precision)).to eq(expected)
      end
    end
  end
end
