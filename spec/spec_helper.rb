require "influxdb"
require "webmock/rspec"
begin
  require "pry-byebug"
rescue LoadError
end

RSpec.configure do |config|
  config.color = ENV["TRAVIS"] != "true"

  if config.files_to_run.one? || ENV["TRAVIS"] == "true"
    config.formatter = :documentation
  else
    config.formatter = :progress
  end
end

InfluxDB::Logging.logger = Logger.new(STDOUT) if ENV['LOG']
