source "https://rubygems.org"

gem "dor-services", "~> 4.12.1"
gem 'lyber-core', '~> 3.2', '>=3.2.4'
gem "daemons" # XXX: is this needed anymore?
gem "jhove-service", ">=1.0.2"
gem "pony"
gem "whenever"
gem 'rake', '~> 10.3.2'
gem "rspec", "2.14.1"
gem 'net-ssh-krb'
gem "pry-debugger", '0.2.2', :platform => :ruby_19 # for bin/console
gem 'robot-controller', '~> 1.0' # requires Resque
gem 'slop', '~> 3.5.0'          # for bin/run_robot
gem 'addressable', '2.3.5'      # pin to avoid RDF bug
gem 'nokogiri' , '1.6.2.1'

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
	gem 'capistrano', '~> 3.2.1'
  gem 'capistrano-bundler', '~> 1.1'
  gem 'lyberteam-capistrano-devel', "~> 3.0"
  gem 'holepicker', '~> 0.3', '>= 0.3.3'
end

