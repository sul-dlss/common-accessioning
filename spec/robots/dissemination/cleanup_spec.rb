# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Dissemination::Cleanup do
  subject(:robot) { described_class.new }

  let(:druid) { 'druid:bb222cc3333' }
  let(:process) { instance_double(Dor::Workflow::Response::Process, lane_id: 'default') }

  describe '#perform' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, workspace: workspace_client) }
    let(:workspace_client) { instance_double(Dor::Services::Client::Workspace, cleanup: true) }
    let(:workflow_client) { instance_double(Dor::Workflow::Client, process:) }

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
      allow(LyberCore::WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    end

    it 'is successful' do
      test_perform(robot, druid)
      expect(workspace_client).to have_received(:cleanup).with(workflow: 'disseminationWF', lane_id: 'default')
    end
  end
end
