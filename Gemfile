# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'activesupport', '~> 5.2'
gem 'assembly-image', '~> 1.7'
gem 'assembly-objectfile', '>=1.6.6'
gem 'config', '~> 1.7'
gem 'dor-fetcher', '~> 1.3'
gem 'dor-services', '~> 8.0'
gem 'dor-services-client', '~> 3.9'
gem 'dor-workflow-client', '~> 3.11'
gem 'honeybadger'
gem 'jhove-service', '~> 1.3'
gem 'lyber-core', '~> 5.4'
gem 'marc' # for etd_submit/submit_marc
gem 'moab-versioning', '~> 4.0'
gem 'net-sftp', '~> 2.1' # for binder_batch_transfer
gem 'nokogiri'
gem 'pony' # send email, for etd_submit/build_symphony_marc
gem 'preservation-client', '~> 2.0'
gem 'pry'
gem 'pry-byebug', :platform => [:ruby_20, :ruby_21]
gem 'rake'
gem 'resque'
gem 'resque-pool'
gem 'slop'
gem 'systemu', '~> 2.6'
gem 'uuidtools' # For models/etd_metadata
gem 'whenever'
gem 'zeitwerk', '~> 2.1'

group :test do
  gem 'coveralls', require: false
  gem 'rspec', '~> 3.0'
  gem 'simplecov'
  gem 'webmock'
end

group :development do
  if File.exists?(mygems = File.join(ENV['HOME'], '.gemfile'))
    instance_eval(File.read(mygems))
  end
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-bundler', '~> 1.1'
  gem 'capistrano-resque-pool'
  gem 'dlss-capistrano', '~> 3.1'
end

group :development, :test do
  gem 'rubocop', '~> 0.77.0'
  gem 'rubocop-rspec'
  gem 'byebug'
end
