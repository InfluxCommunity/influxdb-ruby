require "rake/testtask"
require "bundler/gem_tasks"
require "rubocop/rake_task"

RuboCop::RakeTask.new

targeted_files = ARGV.drop(1)
file_pattern   = targeted_files.empty? ? "spec/**/*_spec.rb" : targeted_files

require "rspec/core"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = FileList[file_pattern]
end

if ENV.key?("TRAVIS")
  task default: %i[spec]
else
  task default: %i[spec rubocop]
end

task :console do
  lib = File.expand_path("lib", __dir__)
  $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
  require "influxdb"

  begin
    require "pry-byebug"
    Pry.start
  rescue LoadError
    puts \
      "Could not load pry-byebug. Create a file Gemfile.local with",
      "the following line, if you want to get rid of this message:",
      "",
      "\tgem \"pry-byebug\"",
      "",
      "(don't forget to run bundle afterwards). Falling back to IRB.",
      ""

    require "irb"
    require "irb/completion"
    ARGV.clear
    IRB.start
  end
end
