$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require 'rubygems'
require "bundler/setup"
require 'lyber_core'

# Load the environment file based on Environment.  Default to local
if(ENV.include?('ROBOT_ENVIRONMENT'))
  environment = ENV['ROBOT_ENVIRONMENT']
else
  environment = ENV['ROBOT_ENVIRONMENT']= 'development'
end

env_file = File.expand_path(File.dirname(__FILE__) + "/../config/environments/#{environment}")
puts "Loading config from #{env_file}"
require env_file

ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + "/..")






  