require "influxdb"
require "webmock/rspec"

# rubocop:disable Lint/HandleExceptions
begin
  require "pry-byebug"
rescue LoadError
end
# rubocop:enable Lint/HandleExceptions

def min_influx_version(version)
  v = ENV.fetch("influx_version", "0")
  return true if v == "nightly"

  current = Gem::Version.new(v)
  current >= Gem::Version.new(version)
end

RSpec.configure do |config|
  config.color = ENV["TRAVIS"] != "true"
  config.filter_run_excluding smoke: ENV["TRAVIS"] != "true" || !ENV.key?("influx_version")
  puts "SMOKE TESTS ARE NOT CURRENTLY RUNNING" if ENV["TRAVIS"] != "true"

  # rubocop:disable Style/ConditionalAssignment
  if config.files_to_run.one? || ENV["TRAVIS"] == "true"
    config.formatter = :documentation
  else
    config.formatter = :progress
  end
  # rubocop:enable Style/ConditionalAssignment

  if ENV["LOG"]
    Dir.mkdir("tmp") unless Dir.exist?("tmp")
    logfile = File.open("tmp/spec.log", File::WRONLY | File::TRUNC | File::CREAT)

    InfluxDB::Logging.logger = Logger.new(logfile).tap do |logger|
      logger.formatter = proc { |severity, _datetime, progname, message|
        format "%-5s - %s: %s\n", severity, progname, message
      }
    end

    config.before(:each) do
      InfluxDB::Logging.logger.info("RSpec") { self.class }
      InfluxDB::Logging.logger.info("RSpec") { @__inspect_output }
      InfluxDB::Logging.log_level = Logger.const_get(ENV["LOG"].upcase)
    end

    config.after(:each) do
      logfile.write "\n"
    end
  end
end
