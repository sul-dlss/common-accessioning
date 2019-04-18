# frozen_string_literal: true

source 'https://rubygems.org'

gem 'activesupport', '~> 5.2'
gem 'dor-fetcher', '~> 1.3'
gem 'dor-services', '~> 6.5'
gem 'dor-services-client', '>=1.4.0'
gem 'etd_model'
gem 'lyber-core',  '>=4.1.3'
gem 'marc' # for etd_submit/submit_marc
gem 'jhove-service', '>=1.1.5'
gem 'moab-versioning', '~> 4.0'
gem 'whenever'
gem 'rake'
gem 'rspec', '~> 3.0'
gem 'resque'
gem 'resque-pool'
gem 'pony' # send email, for etd_submit/build_symphony_marc
gem 'pry'
gem 'pry-byebug', :platform => [:ruby_20, :ruby_21]
gem 'slop'
gem 'net-sftp', '~> 2.1' # for binder_batch_transfer
gem 'nokogiri'
gem 'honeybadger'
gem 'assembly-image', '~> 1.7'
gem 'assembly-objectfile', '>=1.6.6'
gem 'uuidtools' # For models/etd_metadata

group :test do
  gem 'simplecov'
  gem 'coveralls', require: false
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
  gem 'rubocop', '~> 0.60.0'
  gem 'byebug'
end
