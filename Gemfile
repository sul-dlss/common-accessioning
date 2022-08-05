# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'activesupport', '~> 7.0'
gem 'assembly-image', '~> 2.0' # ruby-vips is used by 2.0.0 for improved image processing
gem 'assembly-objectfile', '~> 2.1'
gem 'config', '~> 2.2'
gem 'dor-services-client', '~> 12.0'
gem 'dor-workflow-client', '~> 5.0'
gem 'dry-struct', '~> 1.0'
gem 'dry-types', '~> 1.1'
gem 'druid-tools', '~> 2.1'
gem 'honeybadger'
gem 'lyber-core', '~> 6.1'
gem 'nokogiri'
gem 'pry'
gem 'pry-byebug', platform: %i[ruby_20 ruby_21]
gem 'rake'
gem 'resque', '~> 2.0' # bundler used 1.x otherwise
gem 'resque-pool'
gem 'slop'
gem 'zeitwerk', '~> 2.1'

# openapi_parser is an indirect dependency that's being pinned for now, because 1.0 introduces
# stricter date-time format parsing, which breaks the test suite
# see https://app.circleci.com/pipelines/github/sul-dlss/common-accessioning/388/workflows/f4199f50-7566-41c1-9e56-683321958076/jobs/941
gem 'openapi_parser', '< 1.0'

group :test do
  gem 'equivalent-xml'
  gem 'rspec', '~> 3.0'
  gem 'rspec_junit_formatter' # needed for test coverage in CircleCI
  gem 'simplecov', require: 'false'
  gem 'webmock'
end

group :development do
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-bundler', '~> 1.1'
  gem 'dlss-capistrano', require: false
end

group :development, :test do
  gem 'byebug'
  gem 'rubocop'
  gem 'rubocop-rspec'
end
