source :rubygems
source "http://sul-gems-prod.stanford.edu"

gem "dor-services", "~> 3.17"
gem "lyber-core"
gem "daemons"
gem "jhove-service", ">=1.0.2"
gem "pony"
gem "whenever"
gem "rake"
gem "rspec", "< 2.0"

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
	gem "lyberteam-devel", ">= 0.7.0"
end

