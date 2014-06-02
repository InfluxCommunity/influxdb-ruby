require "bundler/gem_tasks"

targeted_files = ARGV.drop(1)
file_pattern = targeted_files.empty? ? 'spec/**/*_spec.rb' : targeted_files

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = FileList[file_pattern]
end

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
end

task :default => :spec

task :console do
  require 'irb'
  require 'irb/completion'
  require 'influxdb'
  ARGV.clear
  IRB.start
end
