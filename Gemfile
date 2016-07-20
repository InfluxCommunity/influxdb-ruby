source "https://rubygems.org"

if RUBY_ENGINE != "jruby" && RUBY_VERSION < "2.0"
  gem "json", "~> 1.8.3"
end

gemspec

local_gemfile = 'Gemfile.local'

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
end
