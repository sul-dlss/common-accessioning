# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Ocr::StartOcr do
  subject(:perform) { test_perform(robot, druid) }

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
  let(:ocr) { instance_double(Dor::TextExtraction::Ocr, possible?: possible) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Dor::TextExtraction::Ocr).to receive(:new).and_return(ocr)
  end

  context 'when the object is not opened and is possible to OCR' do
    let(:version_open) { false }
    let(:possible) { true }

    it 'opens the object' do
      perform
      expect(version_client).to have_received(:open)
    end
  end

  context 'when the object is not opened and is not possible to OCR' do
    let(:version_open) { false }
    let(:possible) { false }
    let(:note) { 'No files available or invalid object for OCR' }
    let(:workflow) { 'ocrWF' }
    let(:status) { 'skipped' }
    let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow: workflow_response) }
    let(:workflow_response) { instance_double(Dor::Workflow::Response::Workflow, incomplete_processes: [start_ocr, fetch_files, ocr_create, end_ocr]) }
    # NOTE: this is just mocking a workflow response, it doesn't actually have to be fully accurate
    # we just need to expect we will update the status of all steps except start-ocr
    let(:start_ocr) { instance_double(Dor::Workflow::Response::Process, name: 'start-ocr') }
    let(:fetch_files) { instance_double(Dor::Workflow::Response::Process, name: 'fetch-files') }
    let(:ocr_create) { instance_double(Dor::Workflow::Response::Process, name: 'ocr-create') }
    let(:end_ocr) { instance_double(Dor::Workflow::Response::Process, name: 'end-ocr') }

    let(:return_status) { perform.status }

    before do
      allow(LyberCore::WorkflowClientFactory).to receive(:build).and_return(workflow_client)
      allow(workflow_client).to receive(:update_status)
    end

    it 'sets all steps (except self) in the workflow to waiting and returns status of skipped for self' do
      perform
      expect(workflow_client).not_to have_received(:update_status).with(druid:, workflow:, process: 'start-ocr', status:, note:)
      expect(workflow_client).to have_received(:update_status).with(druid:, workflow:, process: 'fetch-files', status:, note:)
      expect(workflow_client).to have_received(:update_status).with(druid:, workflow:, process: 'ocr-create', status:, note:)
      expect(workflow_client).to have_received(:update_status).with(druid:, workflow:, process: 'end-ocr', status:, note:)
      expect(return_status).to eq status
    end
  end

  context 'when the object is already opened' do
    let(:version_open) { true }
    let(:possible) { true }

    it 'raises an error' do
      expect { perform }.to raise_error('Object is already open')
    end
  end
end
