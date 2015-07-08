require "influxdb"
require "webmock/rspec"
begin
  require "pry-byebug"
rescue LoadError
end

InfluxDB::Logging.logger = Logger.new(STDOUT) if ENV['LOG']
