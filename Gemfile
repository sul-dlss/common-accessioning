# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'activesupport', '~> 5.2'
gem 'assembly-image', '~> 1.7'
gem 'assembly-objectfile', '>=1.6.6'
gem 'config', '~> 2.2'
gem 'dor-services-client', '~> 6.2'
gem 'dor-workflow-client', '~> 3.18'
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

group :test do
  gem 'equivalent-xml'
  gem 'rspec', '~> 3.0'
  gem 'rspec_junit_formatter' # needed for test coverage in CircleCI
  gem 'simplecov', '~> 0.17.0', require: 'false' # See https://github.com/codeclimate/test-reporter/issues/413
  gem 'webmock'
end

group :development do
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-bundler', '~> 1.1'
  gem 'capistrano-resque-pool'
  gem 'dlss-capistrano', '~> 3.1'
end

group :development, :test do
  gem 'byebug'
  gem 'rubocop', '~> 0.77.0'
  gem 'rubocop-rspec'
end
