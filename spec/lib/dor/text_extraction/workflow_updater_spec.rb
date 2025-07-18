# frozen_string_literal: true

describe Dor::TextExtraction::WorkflowUpdater do
  subject(:updater) { described_class.new }

  let(:druid) { 'bb222cc3333' }
  let(:object_client) { instance_double(Dor::Services::Client::Object) }
  let(:object_workflow) { instance_double(Dor::Services::Client::ObjectWorkflow, process: workflow_process) }
  let(:workflow_process) { instance_double(Dor::Services::Client::Process, update: true, update_error: true, status: 'queued') }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(object_client).to receive(:workflow).with(workflow).and_return(object_workflow)
    allow(object_workflow).to receive(:process).with(step).and_return(workflow_process)
  end

  describe 'ocrWF' do
    let(:workflow) { 'ocrWF' }
    let(:step) { 'ocr-create' }

    describe '#mark_ocr_create_completed' do
      it 'calls the workflow_process to set completed status' do
        updater.mark_ocr_create_completed(druid)
        expect(workflow_process).to have_received(:update).with(status: 'completed')
      end
    end

    describe '#mark_ocr_create_errored' do
      it 'calls the workflow_process to set error status and message' do
        updater.mark_ocr_create_errored(druid, error_msg: 'Something went wrong')
        expect(workflow_process).to have_received(:update_error).with(error_msg: 'Something went wrong')
      end
    end
  end

  describe 'speechToTextWF' do
    let(:workflow) { 'speechToTextWF' }
    let(:step) { 'stt-create' }

    describe '#mark_stt_create_completed' do
      it 'calls the workflow_process to set completed status' do
        updater.mark_stt_create_completed(druid)
        expect(workflow_process).to have_received(:update).with(status: 'completed')
      end
    end

    describe '#mark_stt_create_errored' do
      it 'calls the workflow_process to set error status and message' do
        updater.mark_stt_create_errored(druid, error_msg: 'Something went wrong')
        expect(workflow_process).to have_received(:update_error).with(error_msg: 'Something went wrong')
      end
    end
  end
end
