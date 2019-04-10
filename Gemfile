# frozen_string_literal: true

source 'https://rubygems.org'

gem 'activesupport', '~> 5.2'
gem 'dor-fetcher', '~> 1.3'
gem 'dor-services', '~> 6.5'
gem 'dor-services-client', '>=1.4.0'
gem 'lyber-core',  '>=4.1.3'
gem 'jhove-service', '>=1.1.5'
gem 'whenever'
gem 'rake'
gem 'rspec', '~> 3.0'
gem 'resque'
gem 'resque-pool'
gem 'pry'
gem 'pry-byebug', :platform => [:ruby_20, :ruby_21]
gem 'slop'
gem 'nokogiri'
gem 'honeybadger'

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
end
