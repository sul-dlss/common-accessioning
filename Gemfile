# frozen_string_literal: true

source 'https://rubygems.org'

gem 'activesupport', '~> 5.1.0' # 5.2.0 breaks: "can't modify frozen ActiveSupport::HashWithIndifferentAccess"
gem 'activemodel', '~> 5.1.0' # needed so activesupport can be ~> 5.1.0
gem 'dor-services', '~> 6.0', '>= 6.0.5'
gem 'lyber-core',  '>=4.1.3'
gem 'jhove-service', '>=1.1.5'
gem 'whenever'
gem 'rake'
gem 'rspec', '~> 3.0'
gem 'resque'
gem 'pry'
gem 'pry-byebug', :platform => [:ruby_20, :ruby_21]
gem 'robot-controller', '~> 2.0'
gem 'slop'
gem 'nokogiri'
gem 'honeybadger'

group :test do
  gem 'simplecov'
  gem 'coveralls', require: false
end

group :development do
  if File.exists?(mygems = File.join(ENV['HOME'], '.gemfile'))
    instance_eval(File.read(mygems))
  end
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-bundler', '~> 1.1'
  gem 'dlss-capistrano', '~> 3.1'
end

group :development, :test do
  gem 'rubocop', '~> 0.60.0'
end
