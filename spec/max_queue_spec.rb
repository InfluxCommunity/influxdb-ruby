require 'spec_helper'

describe InfluxDB::MaxQueue do
  it "should inherit from Queue" do
    InfluxDB::MaxQueue.new.should be_a(Queue)
  end

  context "#new" do
    it "should allow max_depth to be set" do
      queue = InfluxDB::MaxQueue.new(500)
      queue.max.should == 500
    end
  end

  context "#push" do
    it "should allow an item to be added if the queue is not full" do
      queue = InfluxDB::MaxQueue.new(5)
      queue.size.should be_zero
      queue.push(1)
      queue.size.should == 1
    end

    it "should not allow items to be added if the queue is full" do
      queue = InfluxDB::MaxQueue.new(5)
      queue.size.should be_zero
      5.times { |n| queue.push(n) }
      queue.size.should == 5
      queue.push(6)
      queue.size.should == 5
    end
  end
end
