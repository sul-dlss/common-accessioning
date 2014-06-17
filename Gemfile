source "https://rubygems.org"
source "http://sul-gems-prod.stanford.edu"

gem "dor-services", "~> 4.6.6.2"
gem "lyber-core", "~> 2.4"
gem "daemons"
gem "jhove-service", ">=1.0.2"
gem "pony"
gem "whenever"
gem "rake"
gem "rspec", "<2.99"
gem 'net-ssh-krb'
gem 'addressable', '2.3.5'


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
  gem 'holepicker', '~>0.3', '>= 0.3.3'
end

