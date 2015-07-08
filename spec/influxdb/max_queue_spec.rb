require 'spec_helper'

describe InfluxDB::MaxQueue do
  specify { is_expected.to be_a(Queue) }

  context "#new" do
    it "allows max_depth to be set" do
      expect(described_class.new(500).max).to eq 500
    end
  end

  context "#push" do
    let(:queue) { described_class.new(5) }

    it "allows an item to be added if the queue is not full" do
      expect(queue.size).to be_zero
      queue.push(1)
      expect(queue.size).to eq 1
    end

    it "doesn't allow items to be added if the queue is full" do
      expect(queue.size).to be_zero
      5.times { |n| queue.push(n) }
      expect(queue.size).to eq 5
      queue.push(6)
      expect(queue.size).to eq 5
    end
  end
end
