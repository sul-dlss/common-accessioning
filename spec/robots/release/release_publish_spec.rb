# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Release::ReleasePublish do
  subject(:perform) { robot.perform(druid) }

  let(:druid) { 'aa222cc3333' }
  let(:robot) { described_class.new }
  let(:object_client) { instance_double(Dor::Services::Client::Object, publish: true) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  it 'calls the publish metadata service with the dor item' do
    expect(perform.status).to eq 'noop'
    expect(object_client).to have_received(:publish)
  end
end
