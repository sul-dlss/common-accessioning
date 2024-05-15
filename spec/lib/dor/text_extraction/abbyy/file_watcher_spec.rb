# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::Abbyy::FileWatcher do
  include_context 'with abbyy dir'

  let(:druid) { 'ab123cd4567' }
  let(:workflow_updater) { instance_double(Dor::TextExtraction::WorkflowUpdater) }
  let(:listener_options) { {} }
  let(:file_watcher) { described_class.new(workflow_updater:, listener_options:) }

  before do
    allow(Settings.sdr).to receive_messages(
      abbyy_result_path: abbyy_result_xml_path,
      abbyy_exception_path: abbyy_exceptions_path
    )
    allow(workflow_updater).to receive(:mark_ocr_completed)
    allow(workflow_updater).to receive(:mark_ocr_errored)
  end

  context 'with polling disabled' do
    it 'notifies SDR when a successful result is created' do
      file_watcher.start
      create_abbyy_result(abbyy_result_xml_path, druid:)
      file_watcher.stop
      expect(workflow_updater).to have_received(:mark_ocr_completed).with(druid)
    end

    it 'notifies SDR when an exception result is created' do
      file_watcher.start
      create_abbyy_result(abbyy_exceptions_path, druid:, success: false)
      file_watcher.stop
      expect(workflow_updater).to have_received(:mark_ocr_errored).with(druid)
    end
  end

  context 'with polling enabled' do
    let(:listener_options) { { force_polling: true } }

    it 'notifies SDR when a successful result is created' do
      file_watcher.start
      create_abbyy_result(abbyy_result_xml_path, druid:)
      sleep(1) # Allow enough time to poll the filesystem
      file_watcher.stop
      expect(workflow_updater).to have_received(:mark_ocr_completed).with(druid)
    end

    it 'notifies SDR when an exception result is created' do
      file_watcher.start
      create_abbyy_result(abbyy_exceptions_path, druid:, success: false)
      sleep(1) # Allow enough time to poll the filesystem
      file_watcher.stop
      expect(workflow_updater).to have_received(:mark_ocr_errored).with(druid)
    end
  end
end
