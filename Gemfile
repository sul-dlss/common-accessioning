# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'activesupport'
gem 'assembly-image'
gem 'assembly-objectfile'
gem 'aws-sdk-batch' # used for submitting jobs for speech-to-text workflow
gem 'aws-sdk-s3' # used for sending files to S3 for the speech-to-text workflow
gem 'aws-sdk-sqs' # used for receiving sqs messages from the speech-to-text workflow
gem 'cocina-models'
gem 'config'
gem 'dor-services-client'
gem 'dry-struct'
gem 'dry-types'
gem 'druid-tools'
gem 'honeybadger'
gem 'listen'
gem 'lyber-core'
gem 'nokogiri'
gem 'purl_fetcher-client'
gem 'preservation-client'
gem 'pry'
gem 'rake'
gem 'sidekiq'
gem 'slop'
gem 'whenever', require: false
gem 'zeitwerk'

source 'https://gems.contribsys.com/' do
  gem 'sidekiq-pro'
end

group :test do
  gem 'equivalent-xml'
  gem 'rspec'
  gem 'rspec_junit_formatter' # needed for test coverage in CircleCI
  gem 'simplecov', require: 'false'
  gem 'webmock'
end

group :development do
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'debug'
  gem 'dlss-capistrano', require: false
  gem "ruby-debug-completion"
end

group :development, :test do
  gem 'rubocop'
  gem 'rubocop-capybara'
  gem 'rubocop-factory_bot'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails'
end
