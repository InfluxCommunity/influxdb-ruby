#!/bin/sh

set -ex

# Rubygems 3.0 requires Ruby 2.3
if [ "$TRAVIS_RUBY_VERSION" = "2.2" ]; then
	gem update --system 2.7.7
else
	gem update --system --no-doc
fi

# Bundler 2.0 fails spectacular
gem uninstall bundler || true
gem install bundler --no-doc --version '< 2'
