$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "robots"))

require 'rubygems'
require "bundler/setup"
require 'dor-services'
require 'lyber_core'

# Load the environment file based on Environment.  Default to development
if(ENV.include?('ROBOT_ENVIRONMENT'))
  environment = ENV['ROBOT_ENVIRONMENT']
else
  environment = ENV['ROBOT_ENVIRONMENT']= 'development'
end

ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/..")

Dir["#{ROBOT_ROOT}/lib/**/*.rb"].each { |f| require f }
Dir["#{ROBOT_ROOT}/robots/**/*.rb"].each { |f| require f }

env_file = File.expand_path(File.dirname(__FILE__) + "/./environments/#{environment}")
puts "Loading config from #{env_file}"
require env_file







  