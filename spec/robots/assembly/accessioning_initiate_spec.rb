# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::AccessioningInitiate do
  subject(:robot) { described_class.new }

  let(:base_url) { 'http://dor-services.example.edu' }
  let(:druid) { 'aa222cc3333' }
  let(:namespaced_druid) { "druid:#{druid}" }
  let(:process) { instance_double(Dor::Workflow::Response::Process, lane_id: 'default') }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil, process: process) }
  let(:workspace_client) { instance_double(Dor::Services::Client::Workspace, create: nil) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, current: '1') }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, workspace: workspace_client, find: object)
  end

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when the type is item' do
    let(:object) do
      Cocina::Models::DRO.new(externalIdentifier: '123',
                              type: Cocina::Models::DRO::TYPES.first,
                              label: 'my dro',
                              version: 1)
    end

    it 'initiates accessioning' do
      robot.perform(druid)
      expect(workspace_client).to have_received(:create)
        .with(source: 'spec/test_input2/aa/222/cc/3333')
      expect(workflow_client).to have_received(:create_workflow_by_name)
        .with(namespaced_druid, 'accessionWF', version: '1', lane_id: 'default')
    end
  end

  context 'when the type is set' do
    let(:object) do
      Cocina::Models::Collection.new(externalIdentifier: '123',
                                     type: Cocina::Models::Collection::TYPES.first,
                                     label: 'my collection',
                                     version: 1)
    end

    it 'initiates accessioning, but does not initialize the workspace' do
      robot.perform(druid)
      expect(workspace_client).not_to have_received(:create)
      expect(workflow_client).to have_received(:create_workflow_by_name)
        .with(namespaced_druid, 'accessionWF', version: '1', lane_id: 'default')
    end
  end
end
