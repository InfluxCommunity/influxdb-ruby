require "bundler/gem_tasks"

targeted_files = ARGV.drop(1)
file_pattern = targeted_files.empty? ? 'spec/**/*_spec.rb' : targeted_files

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = FileList[file_pattern]
end

task default: :spec

task :console do
  lib = File.expand_path('../lib', __FILE__)
  $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
  require "influxdb"

  begin
    require "pry-byebug"
    Pry.start
  rescue LoadError
    puts <<-TEXT.gsub(/^\s{6}([^ ])/, '\1')
      Could not load pry-byebug. Create a file Gemfile.local with
      the following line, if you want to get rid of this message:

      \tgem "pry-byebug"

      (don't forget to run bundle afterwards). Falling back to IRB.

    TEXT

    require "irb"
    ARGV.clear
    IRB.start
  end
end
