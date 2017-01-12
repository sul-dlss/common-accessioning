source 'https://rubygems.org'

gem 'activesupport'
gem 'dor-services', '~> 5.11'
gem 'lyber-core', '~> 4.0', '>= 4.0.3'
gem 'jhove-service', '>=1.0.2'
gem 'whenever'
gem 'rake'
gem 'rspec', '~> 3.0'
gem 'resque'
gem 'pry'
gem 'pry-byebug', :platform => [:ruby_20, :ruby_21]
gem 'robot-controller', '~> 2.0'
gem 'slop'
gem 'nokogiri'

# Pin bluepill to master branch of git since the gem release 0.1.2 is
# incompatible with rails 5, can remove this when a new gem is released
gem 'bluepill', git: 'https://github.com/bluepill-rb/bluepill.git'

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
