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

platform :mri_18 do
  gem 'net-ssh-kerberos'
end

platform :mri_19 do
  gem 'net-ssh-krb'
  gem 'gssapi', :github => 'cbeer/gssapi'
end

group :test do
	gem "rcov", :platform => :ruby_18
	gem "assembly-utils"
end

group :development do
  if File.exists?(mygems = File.join(ENV['HOME'],'.gemfile'))
    instance_eval(File.read(mygems))
  end
	gem "ruby-debug", :platform => :ruby_18
	gem "debugger", :platform => :ruby_19
	gem "lyberteam-capistrano-devel", ">= 0.7.0"
  gem "capistrano", "< 3.0"
	gem "yard"
end

