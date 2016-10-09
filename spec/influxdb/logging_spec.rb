require 'spec_helper'
require 'logger'

describe InfluxDB::Logging do
  class LoggerTest # :nodoc:
    include InfluxDB::Logging

    def write_to_log(level, message)
      log(level, message)
    end

    def block_log(level, &block)
      log(level, &block)
    end
  end

  around do |example|
    old_logger = InfluxDB::Logging.logger
    example.call
    InfluxDB::Logging.logger = old_logger
  end

  it "has a default logger" do
    expect(InfluxDB::Logging.logger).to be_a(Logger)
  end

  it "allows setting of a logger" do
    new_logger = Logger.new(STDOUT)
    InfluxDB::Logging.logger = new_logger
    expect(InfluxDB::Logging.logger).to eq(new_logger)
  end

  it "allows disabling of a logger" do
    InfluxDB::Logging.logger = false
    expect(InfluxDB::Logging.logger).to eql false
  end

  context "when logging is disabled" do
    subject { LoggerTest.new }
    it "does not log" do
      InfluxDB::Logging.logger = false
      expect(InfluxDB::Logging.logger).not_to receive(:debug)
      subject.write_to_log(:debug, 'test')
    end
  end

  context "when included in classes" do
    subject { LoggerTest.new }

    it "logs with string message" do
      expect(InfluxDB::Logging.logger).to receive(:debug).with(an_instance_of(String)).once
      subject.write_to_log(:debug, 'test')
    end

    it "logs with block message" do
      msg = double("message")
      expect(msg).to receive(:expensive_message).and_return("42")
      expect(InfluxDB::Logging.logger).to receive(:debug).and_yield.once
      subject.block_log(:debug) { msg.expensive_message }
    end
  end
end
