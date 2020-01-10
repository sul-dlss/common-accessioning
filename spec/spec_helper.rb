# frozen_string_literal: true

# Make sure specs run with the definitions from test.rb
ENV['ROBOT_ENVIRONMENT'] = 'test'

require 'simplecov'
require 'coveralls'
require 'byebug'

SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  track_files 'bin/**/*'
  track_files 'lib/dor/*.rb'
  track_files 'robots/**/*.rb'
  add_filter '/spec/'
end

require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

require 'pry'
require 'rspec'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow: ['localhost:8983', 'localhost:8984'])
require 'equivalent-xml/rspec_matchers'
require 'support/foxml_helper'

TMP_ROOT_DIR = 'tmp/test_input'

RSpec.configure do |config|
  config.order = :random
end

# Use rsync to create a copy of the test_input directory that we can modify.
def clone_test_input(destination)
  source = 'spec/test_input'
  system "rsync -rqOlt --delete #{source}/ #{destination}/"
end

def setup_release_item(druid, obj_type, members)
  @release_item = Dor::Release::Item.new(druid: druid, skip_heartbeat: true)
  @dor_item = instance_double(Dor::Item)
  allow(@dor_item).to receive_messages(
    id: druid
  )
  allow(@release_item).to receive_messages(
    object: @dor_item,
    object_type: obj_type.to_s.downcase,
    members: members
  )
  allow(Dor::Release::Item).to receive_messages(new: @release_item)
end

def instantiate_fixture(druid, klass = ActiveFedora::Base)
  mask = File.join(fixture_dir, "*_#{druid.sub(/:/, '_')}.xml")
  fname = Dir[mask].first
  return nil if fname.nil?

  item_from_foxml(File.read(fname), klass)
end

def read_fixture(fname)
  File.read(File.join(fixture_dir, fname))
end

def fixture_dir
  @fixture_dir ||= File.join(File.dirname(__FILE__), 'fixtures')
end
