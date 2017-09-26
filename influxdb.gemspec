lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'influxdb/version'

# rubocop:disable Style/SpecialGlobalVars
Gem::Specification.new do |spec|
  spec.name          = "influxdb"
  spec.version       = InfluxDB::VERSION
  spec.authors       = ["Todd Persen"]
  spec.email         = ["influxdb@googlegroups.com"]
  spec.description   = "This is the official Ruby library for InfluxDB."
  spec.summary       = "Ruby library for InfluxDB."
  spec.homepage      = "http://influxdb.org"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features|smoke)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.2.0"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "bundler",  "~> 1.3"
  spec.add_development_dependency "rspec",    "~> 3.6"
  spec.add_development_dependency "webmock",  "~> 3.0"
  spec.add_development_dependency "rubocop",  "~> 0.49"
end
