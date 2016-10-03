require "spec_helper"

RSpec.describe InfluxDB::Query::Builder do
  let(:builder) { described_class.new }

  describe "#quote" do
    subject { builder }

    it "should quote parameters properly" do
      expect(subject.quote(3.14)).to eq "3.14"
      expect(subject.quote(14)).to eq "14"

      expect(subject.quote("3.14")).to eq "'3.14'"
      expect(subject.quote("Ben Hur's Carriage")).to eq "'Ben Hur\\'s Carriage'"

      expect(subject.quote(true)).to eq "true"
      expect(subject.quote(false)).to eq "false"
      expect(subject.quote(0 || 1)).to eq "0"

      expect(subject.quote(:symbol)).to eq "'symbol'"

      expect { subject.quote(/regex/) }.to raise_error(ArgumentError, /Unexpected parameter type Regex/)
    end
  end

  describe "#build" do
    subject { builder.build(query, params) }

    context "named parameters" do
      let(:query)  { "SELECT value FROM rpm WHERE f = %{f_val} group by time(%{minutes}m)" }
      let(:params) { { f_val: "value", minutes: 5 } }

      it { is_expected.to eq "SELECT value FROM rpm WHERE f = 'value' group by time(5m)" }

      context "with string keys" do
        let(:params) { { "f_val" => "value", "minutes" => 5 } }

        it { is_expected.to eq "SELECT value FROM rpm WHERE f = 'value' group by time(5m)" }
      end
    end

    context "positional parameter" do
      let(:query)  { "SELECT value FROM rpm WHERE time > %{1}" }
      let(:params) { [1_437_019_900] }

      it { is_expected.to eq "SELECT value FROM rpm WHERE time > 1437019900" }
    end

    context "missing parameters" do
      let(:query)  { "SELECT value FROM rpm WHERE time > %{1}" }
      let(:params) { [] }

      it { expect { subject }.to raise_error(/key.1. not found/) }
    end

    context "extra parameters" do
      let(:query)  { "SELECT value FROM rpm WHERE time > %{a}" }
      let(:params) { { "a" => 0, "b" => 2 } }

      it { is_expected.to eq "SELECT value FROM rpm WHERE time > 0" }
    end
  end
end
