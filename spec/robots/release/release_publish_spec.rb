# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Release::ReleasePublish do
  let(:druid) { 'aa222cc3333' }
  let(:release_item) { Dor::Release::Item.new(druid: druid, skip_heartbeat: true) }
  let(:dor_item) { instance_double(Dor::Item, id: druid) }
  let(:robot) { described_class.new }
  let(:object_client) { instance_double(Dor::Services::Client::Object, publish: true) }

  before do
    allow(release_item).to receive(:object).and_return(dor_item)
    allow(Dor::Release::Item).to receive_messages(new: release_item)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  it 'calls the publish metadata service with the dor item' do
    robot.perform(druid)
    expect(object_client).to have_received(:publish)
  end
end
