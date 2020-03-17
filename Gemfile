# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'activesupport', '~> 5.2'
gem 'assembly-image', '~> 1.7'
gem 'assembly-objectfile', '>=1.6.6'
gem 'config', '~> 2.2'
gem 'dor-services', '~> 9.1'
gem 'dor-services-client', '~> 4.14'
gem 'dor-workflow-client', '~> 3.18'
gem 'druid-tools', '~> 2.1'
gem 'honeybadger'
gem 'jhove-service', '~> 1.4'
gem 'lyber-core', '~> 6.0'
gem 'marc' # for etd_submit/submit_marc
gem 'moab-versioning', '~> 4.0'
gem 'net-sftp', '~> 2.1' # for binder_batch_transfer
gem 'nokogiri'
gem 'pony' # send email, for etd_submit/build_symphony_marc
gem 'preservation-client', '>= 3.0' # 3.x or greater is needed for token auth
gem 'pry'
gem 'pry-byebug', platform: %i[ruby_20 ruby_21]
gem 'rake'
gem 'resque', '~> 2.0' # bundler used 1.x otherwise
gem 'resque-pool'
gem 'slop'
gem 'systemu', '~> 2.6'
gem 'uuidtools' # For models/etd_metadata
gem 'whenever'
gem 'zeitwerk', '~> 2.1'

group :test do
  gem 'coveralls', require: false
  gem 'rspec', '~> 3.0'
  gem 'simplecov', '~> 0.17.1' # 0.18 breaks reporting to coveralls `undefined method `coverage' for #<SimpleCov::SourceFile:0x0000561b4563cd18>`
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
