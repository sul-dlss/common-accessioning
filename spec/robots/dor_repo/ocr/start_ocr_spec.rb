# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Ocr::StartOcr do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }

  let(:object) { build(:dro, id: druid) }
  let(:workspace_client) { instance_double(Dor::Services::Client::Workspace) }
  let(:version_client) do
    instance_double(Dor::Services::Client::ObjectVersion,
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

  context 'when the object is not opened and it is possible to OCR' do
    let(:version_open) { false }
    let(:possible) { true }

    before { allow(version_client).to receive(:open).and_return(true) }

    it 'opens the object' do
      perform
      expect(version_client).to have_received(:open)
    end
  end

  context 'when the object is not opened and it is possible to OCR, but open version fails' do
    let(:version_open) { false }
    let(:possible) { true }

    before { allow(Honeybadger).to receive(:notify) }

    context 'when open version fails twice and then succeeds' do
      before do
        count = 0
        allow(version_client).to receive(:open) do |*_args|
          count += 1
          raise Dor::Services::Client::Error unless count > 2

          true
        end
      end

      it 'retries the first two errors, then calls open again and logs to honeybadger' do
        expect { perform }.not_to raise_error
        expect(version_client).to have_received(:open).thrice # shakespeare coding (first two times fail, third time succeeds)
        expect(Honeybadger).to have_received(:notify).twice # two calls to HB for the first two failures
      end
    end

    context 'when open version fails and exceeds maximum tries' do
      before { allow(version_client).to receive(:open).and_raise(Dor::Services::Client::Error) }

      it 'logs to honeybadger and then raises the error' do
        expect { perform }.to raise_error(Dor::Services::Client::Error)
        expect(version_client).to have_received(:open).thrice # shakespeare coding (all three times fail)
        expect(Honeybadger).to have_received(:notify).twice # two calls to HB for the first two failures
      end
    end
  end

  context 'when the object is not opened and it is not possible to OCR' do
    let(:version_open) { false }
    let(:possible) { false }
    let(:note) { 'No files available or invalid object for OCR' }
    let(:workflow) { 'ocrWF' }
    let(:status) { 'skipped' }
    let(:workflow_client) { instance_double(Dor::Workflow::Client) }
    # NOTE: this is just mocking a workflow response, it doesn't actually have to be fully accurate
    # we just need to expect we will update the status of all steps except start-ocr
    let(:skip_all) { instance_double(Dor::Workflow::Response, name: 'skip-all') }

    let(:return_status) { perform.status }

    before do
      allow(LyberCore::WorkflowClientFactory).to receive(:build).and_return(workflow_client)
      allow(workflow_client).to receive(:skip_all)
    end

    it 'sets sends a skip_all request to dor-client-workflow' do
      perform
      expect(workflow_client).to have_received(:skip_all).with(druid:, workflow:, note:)
      expect(return_status).to eq status
    end
  end

  context 'when the object is already opened' do
    let(:version_open) { true }
    let(:possible) { true }

    before { allow(version_client).to receive(:open) }

    it 'does nothing' do
      perform
      expect(version_client).not_to have_received(:open)
    end
  end
end
