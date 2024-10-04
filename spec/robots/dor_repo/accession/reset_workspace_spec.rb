# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::ResetWorkspace do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { described_class.new }
  let(:object_client) { instance_double(Dor::Services::Client::Object, workspace: workspace_client) }
  let(:workspace_client) { instance_double(Dor::Services::Client::Workspace, cleanup: nil) }
  let(:process) { instance_double(Dor::Workflow::Response::Process, lane_id: 'default') }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, process:) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(LyberCore::WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  describe '#perform' do
    subject(:perform) { test_perform(robot, druid) }

    let(:return_status) { perform.status }

    it 'resets the workspace' do
      expect(return_status).to eq 'noop'
      expect(workspace_client).to have_received(:cleanup).with(workflow: 'accessionWF', lane_id: 'default')
    end
  end
end
