require "influxdb"
require "webmock/rspec"

begin
  # rubocop:disable Lint/HandleExceptions
  require "pry-byebug"
rescue LoadError
end

RSpec.configure do |config|
  config.color = ENV["TRAVIS"] != "true"

  # rubocop:disable Style/ConditionalAssignment
  if config.files_to_run.one? || ENV["TRAVIS"] == "true"
    config.formatter = :documentation
  else
    config.formatter = :progress
  end

  if ENV["LOG"]
    Dir.mkdir("tmp") unless Dir.exist?("tmp")
    logfile = File.open("tmp/spec.log", File::WRONLY | File::TRUNC | File::CREAT)

    InfluxDB::Logging.logger = Logger.new(logfile).tap do |logger|
      logger.formatter = proc { |severity, _datetime, progname, message|
        "%-5s - %s: %s\n".format severity, progname, message
      }
    end

    config.before(:each) do
      InfluxDB::Logging.logger.info("RSpec") { self.class }
      InfluxDB::Logging.logger.info("RSpec") { @__inspect_output }
    end

    config.after(:each) do
      logfile.write "\n"
    end
  end
end
