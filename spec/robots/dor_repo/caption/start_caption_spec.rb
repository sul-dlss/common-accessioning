# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Caption::StartCaption do
  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }

  let(:object) { build(:dro, id: druid) }
  let(:workspace_client) { instance_double(Dor::Services::Client::Workspace) }
  let(:version_client) do
    instance_double(Dor::Services::Client::ObjectVersion, open: true,
                                                          status: instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: version_open))
  end
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, workspace: workspace_client, find: object)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when the object is not opened' do
    let(:version_open) { false }

    it 'opens the object' do
      expect(test_perform(robot, druid)).to be true
      expect(version_client).to have_received(:open)
    end
  end

  context 'when the object is already opened' do
    let(:version_open) { true }

    it 'raises an error' do
      expect { test_perform(robot, druid) }.to raise_error('Object is already open')
    end
  end
end
