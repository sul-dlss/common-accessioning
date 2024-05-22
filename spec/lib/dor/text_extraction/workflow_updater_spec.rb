# frozen_string_literal: true

describe Dor::TextExtraction::WorkflowUpdater do
  subject(:updater) { described_class.new(workflow:, step:, client:) }

  let(:workflow) { 'ocrWF' }
  let(:step) { 'ocr-create' }
  let(:client) { instance_double(Dor::Workflow::Client) }
  let(:druid) { 'bb222cc3333' }

  before do
    allow(client).to receive(:update_status)
    allow(client).to receive(:update_error_status)
  end

  describe '#mark_ocr_completed' do
    it 'calls the workflow client to set completed status' do
      updater.mark_ocr_completed(druid)
      expect(client).to have_received(:update_status).with(druid:, workflow:, process: step, status: 'completed')
    end
  end

  describe '#mark_ocr_errored' do
    it 'calls the workflow client to set error status and message' do
      updater.mark_ocr_errored(druid, error_msg: 'Something went wrong')
      expect(client).to have_received(:update_error_status).with(druid:, workflow:, process: step, error_msg: 'Something went wrong')
    end
  end
end
