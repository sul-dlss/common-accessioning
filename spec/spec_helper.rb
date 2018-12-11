# frozen_string_literal: true

# Make sure specs run with the definitions from test.rb
environment = ENV['ROBOT_ENVIRONMENT'] = 'test'

require 'simplecov'
require 'coveralls'

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
require 'webmock/rspec'
require 'equivalent-xml/rspec_matchers'

def setup_work_item(druid)
  @work_item = double("work_item")
  allow(@work_item).to receive_messages(druid: druid)
end

def setup_release_item(druid, obj_type, members)
  @release_item = Dor::Release::Item.new(druid: druid, skip_heartbeat: true)
  @dor_item = double(Dor)
  allow(@dor_item).to receive_messages(
    publish_metadata: nil,
    id: druid
  )
  allow(@release_item).to receive_messages(
    object: @dor_item,
    object_type: obj_type.to_s.downcase,
    "is_item?": (obj_type == :item),
    "is_collection?": (obj_type == :collection),
    "is_set?": (obj_type == :set),
    "is_apo?": (obj_type == :apo),
    members: members
  )
  allow(Dor::Release::Item).to receive_messages(new: @release_item)
end
