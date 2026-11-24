# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Ocr::EndOcr do
  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }

  let(:object) { build(:dro, id: druid) }
  let(:workspace_client) { instance_double(Dor::Services::Client::Workspace) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, workspace: workspace_client, find: object)
  end

  let(:process_response) { instance_double(Dor::Services::Response::Process, lane_id: 'low', context: {}) }
  let(:workflow_response) { instance_double(Dor::Services::Response::Workflow, process_for_recent_version: process_response) }
  let(:object_workflow) { instance_double(Dor::Services::Client::ObjectWorkflow, find: workflow_response) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(object_client).to receive(:workflow).with('ocrWF').and_return(object_workflow)
  end

  it 'closes the object in the workflow lane' do
    test_perform(robot, druid)
    expect(version_client).to have_received(:close).with(lane_id: 'low', user_versions: nil)
  end
end
