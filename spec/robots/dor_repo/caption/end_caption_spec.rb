# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Caption::EndCaption do
  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }

  let(:object) { build(:dro, id: druid) }
  let(:workspace_client) { instance_double(Dor::Services::Client::Workspace, create: nil) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, workspace: workspace_client, find: object)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  it 'closes the object' do
    expect(test_perform(robot, druid)).to be true
    expect(version_client).to have_received(:close)
  end
end
