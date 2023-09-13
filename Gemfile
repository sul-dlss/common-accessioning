# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'activesupport', '~> 7.0'
gem 'assembly-image', '~> 2.0' # ruby-vips is used by 2.0.0 for improved image processing
gem 'assembly-objectfile', '~> 2.1'
gem 'config', '~> 2.2'
gem 'dor-services-client', '~> 12.15'
gem 'dor-workflow-client', '~> 5.0'
gem 'dry-struct', '~> 1.0'
gem 'dry-types', '~> 1.1'
gem 'druid-tools', '~> 2.1'
gem 'honeybadger'
gem 'lyber-core', '~> 7.1'
gem 'nokogiri'
gem 'pry'
gem 'pry-byebug', platform: %i[ruby_20 ruby_21]
gem 'rake'
gem 'sidekiq', '~> 7.0'
gem 'slop'
gem 'sul_orcid_client', '~> 0.3'
gem 'zeitwerk', '~> 2.1'

source 'https://gems.contribsys.com/' do
  gem 'sidekiq-pro'
end

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
