# frozen_string_literal: true

# Make sure specs run with the definitions from test.rb
environment = ENV['ROBOT_ENVIRONMENT'] = 'test'

require 'simplecov'
require 'coveralls'
require 'equivalent-xml/rspec_matchers'


SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  track_files "bin/**/*"
  track_files "lib/dor/*.rb"
  track_files "robots/**/*.rb"
  add_filter "/spec/"
end

require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

require 'pry'
require 'rspec'
require 'equivalent-xml/rspec_matchers'
