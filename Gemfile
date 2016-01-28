source 'https://rubygems.org'

gem 'activesupport'
gem 'dor-services', '~> 5.2'
gem 'lyber-core', '~> 3.2', '>=3.2.3'
gem 'daemons'
gem 'jhove-service', '>=1.0.2'
gem 'pony'
gem 'whenever'
gem 'rake'
gem 'rspec', '~> 3.0'
gem 'resque'
gem 'pry'
gem 'pry-byebug', :platform => [:ruby_20, :ruby_21]
gem 'robot-controller', '~> 2.0'
gem 'slop'
gem 'addressable', '2.3.5'
gem 'nokogiri'

group :test do
  gem 'simplecov'
  gem 'assembly-utils'
end

group :development do
  if File.exists?(mygems = File.join(ENV['HOME'], '.gemfile'))
    instance_eval(File.read(mygems))
  end
  gem 'yard'
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-bundler', '~> 1.1'
  gem 'dlss-capistrano', '~> 3.1'
end
