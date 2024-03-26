# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'activesupport', '~> 7.0'
gem 'assembly-image', '~> 2.0' # ruby-vips is used by 2.0.0 for improved image processing
gem 'assembly-objectfile', '~> 2.1'
gem 'config'
gem 'dor-services-client', '~> 14.4'
gem 'dor-workflow-client', '~> 7.0'
gem 'dry-struct', '~> 1.0'
gem 'dry-types', '~> 1.1'
gem 'druid-tools'
gem 'honeybadger'
gem 'lyber-core', '~> 7.3'
gem 'nokogiri'
gem 'preservation-client'
gem 'pry'
gem 'rake'
gem 'sidekiq', '~> 7.0'
gem 'slop'
gem 'sul_orcid_client'
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
  gem 'pry-byebug', platform: %i[ruby_20 ruby_21]
  gem 'rubocop'
  gem 'rubocop-rspec'
end
