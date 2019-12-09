# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::AccessioningInitiate do
  subject(:robot) { described_class.new(druid: druid) }

  let(:base_url) { 'http://dor-services.example.edu' }
  let(:druid) { 'aa222cc3333' }
  let(:namespaced_druid) { "druid:#{druid}" }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil) }
  let(:workspace_client) { instance_double(Dor::Services::Client::Workspace, create: nil) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, current: '1') }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, workspace: workspace_client)
  end

  before do
    allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when the type is item' do
    before do
      @assembly_item = setup_assembly_item(druid, :item)
    end

    it 'initiates accessioning' do
      expect(@assembly_item).to be_item
      robot.perform(@assembly_item)
      expect(workspace_client).to have_received(:create)
        .with(source: 'spec/test_input2/aa/222/cc/3333')
      expect(workflow_client).to have_received(:create_workflow_by_name)
        .with(namespaced_druid, 'accessionWF', version: '1')
    end
  end

  context 'when the type is set' do
    before do
      @assembly_item = setup_assembly_item(druid, :set)
    end

    it 'initiates accessioning, but does not initialize the workspace' do
      expect(@assembly_item).not_to be_item
      robot.perform(@assembly_item)
      expect(workspace_client).not_to have_received(:create)
      expect(workflow_client).to have_received(:create_workflow_by_name)
        .with(namespaced_druid, 'accessionWF', version: '1')
    end
  end
end
