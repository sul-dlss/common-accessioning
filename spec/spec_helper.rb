# Make sure specs run with the definitions from test.rb
environment = ENV['ROBOT_ENVIRONMENT'] = 'test'

bootfile = File.expand_path(File.dirname(__FILE__) + '/../robots/boot')
require bootfile

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
$:.unshift File.join(File.dirname(__FILE__), "..", "robots")

require 'spec'
