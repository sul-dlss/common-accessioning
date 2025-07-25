# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::AccessioningInitiate do
  subject(:robot) { described_class.new }

  let(:base_url) { 'http://dor-services.example.edu' }
  let(:bare_druid) { 'bb222cc3333' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:workspace_client) { instance_double(Dor::Services::Client::Workspace, create: nil) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, workspace: workspace_client, find: object)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when the type is item' do
    let(:object) { build(:dro, id: druid) }

    it 'initiates accessioning' do
      test_perform(robot, druid)
      expect(workspace_client).to have_received(:create)
        .with(source: 'spec/test_input2/bb/222/cc/3333')
      expect(version_client).to have_received(:close)
    end
  end

  context 'when the type is collection' do
    let(:object) { build(:collection, id: druid) }

    it 'initiates accessioning, but does not initialize the workspace' do
      test_perform(robot, druid)
      expect(workspace_client).not_to have_received(:create)
      expect(version_client).to have_received(:close)
    end
  end
end
