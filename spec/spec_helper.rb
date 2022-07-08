# frozen_string_literal: true

# Make sure specs run with the definitions from test.rb
ENV['ROBOT_ENVIRONMENT'] = 'test'

require 'simplecov'

SimpleCov.start do
  track_files 'bin/**/*'
  track_files 'lib/dor/*.rb'
  track_files 'robots/**/*.rb'
  add_filter '/spec/'
end

require File.expand_path("#{__dir__}/../config/boot")

require 'byebug'
require 'pry'
require 'rspec'
require 'webmock/rspec'
WebMock.disable_net_connect!
require 'equivalent-xml/rspec_matchers'
require 'cocina/rspec'

TMP_ROOT_DIR = 'tmp/test_input'

RSpec.configure do |config|
  config.order = :random
  config.default_formatter = 'doc' if config.files_to_run.one?

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
end

# Use rsync to create a copy of the test_input directory that we can modify.
def clone_test_input(destination)
  source = 'spec/test_input'
  system "rsync -rqOlt --delete #{source}/ #{destination}/"
end
