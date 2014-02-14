require 'spec_helper'

describe InfluxDB::Logger do
  class LoggerTest
    include InfluxDB::Logger

    def write_to_log(level, message)
      log(level, message)
    end
  end

  subject { LoggerTest.new }

  context 'with DEBUG level' do
    it 'should not write a log message to STDERR' do
      expect(STDERR).to_not receive(:puts)

      subject.write_to_log(:debug, 'debug')
    end
  end

  context 'with non-DEBUG level' do
    it 'should write a log message to STDERR' do
      expect(STDERR).to receive(:puts).with('[InfluxDB] (info) info')

      subject.write_to_log(:info, 'info')
    end
  end
end
