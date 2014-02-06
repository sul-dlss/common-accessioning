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
	gem "lyberteam-capistrano-devel", "1.2.0"
  gem "capistrano", "< 3.0"
	gem "yard"
	gem "ffi", "1.7.0"
	gem "net-ssh", "2.6.7"
	gem "net-sftp", "2.1.1"
	gem 'gssapi', "1.1.3.stanford"
end

