# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'activesupport', '~> 7.0'
gem 'assembly-image', '~> 2.0' # ruby-vips is used by 2.0.0 for improved image processing
gem 'assembly-objectfile', '~> 2.1'
gem 'aws-sdk-s3' # used for sending files to S3 for the speech-to-text workflow
gem 'config'
gem 'dor-services-client', '~> 14.6'
gem 'dor-workflow-client', '~> 7.0'
gem 'dry-struct', '~> 1.0'
gem 'dry-types', '~> 1.1'
gem 'druid-tools'
gem 'honeybadger'
gem 'lyber-core', '~> 7.5' # 7.5.0 has the ability to set and return workflow context
gem 'nokogiri'
gem 'purl_fetcher-client'
gem 'preservation-client'
gem 'pry'
gem 'rake'
gem 'sidekiq', '~> 7.0'
gem 'slop'
gem 'zeitwerk', '~> 2.1'
gem "listen", "~> 3.9" # used for watching ABBYY OCR output directories

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
