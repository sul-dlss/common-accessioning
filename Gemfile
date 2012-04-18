source :rubygems
source "http://sulair-rails-dev.stanford.edu"

gem "dor-services", "~> 3.0"
gem "lyber-core", ">= 2.1.0"
gem "daemons"
gem "jhove-service"
gem "pony"
gem "whenever"

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
	gem "lyberteam-devel", ">= 0.6.2"
end

