source "https://rubygems.org"
source "http://sul-gems-prod.stanford.edu"

gem "dor-services"
gem "lyber-core"
gem "daemons"
gem "jhove-service", ">=1.0.2"
gem "pony"
gem "whenever"
gem "rake"
gem "rspec"
gem 'net-ssh-krb'


group :test do
	gem "simplecov"
	gem "assembly-utils"
end

group :development do
  if File.exists?(mygems = File.join(ENV['HOME'],'.gemfile'))
    instance_eval(File.read(mygems))
  end
	gem "debugger", :platform => :ruby_19
	gem "lyberteam-capistrano-devel", ">= 0.7.0"
  gem "capistrano", "< 3.0"
	gem "yard"
end

