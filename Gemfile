source "https://rubygems.org"
source "http://sul-gems-prod.stanford.edu"

gem "dor-services", "~> 4.6"
gem "lyber-core", "~> 3.2", ">=3.2.1"
gem "daemons"
gem "jhove-service", ">=1.0.2"
gem "pony"
gem "whenever"
gem "rake"
gem "rspec"
gem 'net-ssh-krb'
gem 'resque'
gem "pry-debugger", '0.2.2', :platform => :ruby_19
gem 'robot-controller'
gem 'dor-workflow-service', '~> 1.6'
gem 'slop'

group :test do
	gem "simplecov"
	gem "assembly-utils"
end

group :development do
  if File.exists?(mygems = File.join(ENV['HOME'],'.gemfile'))
    instance_eval(File.read(mygems))
  end
	gem "debugger", :platform => :ruby_19
	gem "yard"
	gem "capistrano", '~> 3.0'
  gem 'capistrano-bundler', '~> 1.1'
  gem "lyberteam-capistrano-devel", '3.0.0.pre1'
  gem 'holepicker', '~> 0.3', '>= 0.3.3'
end

