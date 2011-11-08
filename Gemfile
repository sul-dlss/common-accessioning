source :rubygems
source "http://sulair-rails-dev.stanford.edu"

gem "dor-services", "2.3.1"
gem "lyber-core", ">= 1.2"
gem "daemons"
gem "jhove-service"
gem "pony"

group :test do
	gem "rake"
	gem "rcov"
	gem "rspec", "< 2.0"
end

group :development do
  if File.exists?(mygems = File.join(ENV['HOME'],'.gemfile'))
    instance_eval(File.read(mygems))
  end
	gem "ruby-debug"
end

