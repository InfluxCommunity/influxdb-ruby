source "https://rubygems.org"

gemspec

gem "webmock", git: "https://github.com/influxdb/webmock.git"

local_gemfile = 'Gemfile.local'

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
end
