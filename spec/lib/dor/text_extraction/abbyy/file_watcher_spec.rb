# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::Abbyy::FileWatcher do
  include_context 'with abbyy dir'

  let(:bare_druid) { 'ab123cd4567' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:logger) { instance_double(Logger) }
  let(:workflow_updater) { instance_double(Dor::TextExtraction::WorkflowUpdater) }
  let(:listener_options) { {} }
  let(:file_watcher) { described_class.new(logger:, workflow_updater:, listener_options:) }
  let(:failure_messages) { ['Error one', 'Error two'] }
  let(:errors_xml) do
    <<~XML
      <Message Type="Error"><Text>#{failure_messages[0]}</Text></Message>
      <Message Type="Error"><Text>#{failure_messages[1]}</Text></Message>
    XML
  end

  before do
    allow(Settings.sdr.abbyy).to receive_messages(
      local_result_path: abbyy_result_xml_path,
      local_exception_path: abbyy_exceptions_path
    )
    allow(logger).to receive(:info)
    allow(workflow_updater).to receive(:mark_ocr_completed)
    allow(workflow_updater).to receive(:mark_ocr_errored)
    allow(Honeybadger).to receive(:notify)
  end

  context 'with polling disabled' do
    it 'notifies SDR when a successful result is created' do
      file_watcher.start
      create_abbyy_result(abbyy_result_xml_path, druid: bare_druid)
      file_watcher.stop
      expect(workflow_updater).to have_received(:mark_ocr_completed).with(druid)
    end

    it 'notifies SDR when an exception result is created' do
      file_watcher.start
      create_abbyy_result(abbyy_exceptions_path, druid: bare_druid, success: false, contents: errors_xml)
      file_watcher.stop
      expect(workflow_updater).to have_received(:mark_ocr_errored).with(druid, error_msg: "Error one\nError two")

      # We use a regex to match the result file path because it's in a containing temp directory for which we don't know the path
      result_file_path_regexp = Regexp.escape("#{abbyy_exceptions_path}/#{bare_druid}.xml.result.xml")
      failure_messages_regexp = Regexp.escape(failure_messages.join('; '))
      expect(logger).to have_received(:info).with(/Found failed OCR results for #{druid} at .*#{result_file_path_regexp}: #{failure_messages_regexp}/)
      context = { druid:, result_path: a_string_matching(/.*#{result_file_path_regexp}/), failure_messages: }
      expect(Honeybadger).to have_received(:notify).with('Found failed OCR results', context:)
    end
  end

  context 'with polling enabled' do
    let(:listener_options) { { force_polling: true } }

    it 'notifies SDR when a successful result is created' do
      file_watcher.start
      create_abbyy_result(abbyy_result_xml_path, druid: bare_druid)
      sleep(1) # Allow enough time to poll the filesystem
      file_watcher.stop
      expect(workflow_updater).to have_received(:mark_ocr_completed).with(druid)
    end

    it 'notifies SDR when an exception result is created' do
      file_watcher.start
      create_abbyy_result(abbyy_exceptions_path, druid: bare_druid, success: false, contents: errors_xml)
      sleep(1) # Allow enough time to poll the filesystem
      file_watcher.stop
      expect(workflow_updater).to have_received(:mark_ocr_errored).with(druid, error_msg: "Error one\nError two")

      # We use a regex to match the result file path because it's in a containing temp directory for which we don't know the path
      result_file_path_regexp = Regexp.escape("#{abbyy_exceptions_path}/#{bare_druid}.xml.result.xml")
      failure_messages_regexp = Regexp.escape(failure_messages.join('; '))
      expect(logger).to have_received(:info).with(/Found failed OCR results for #{druid} at .*#{result_file_path_regexp}: #{failure_messages_regexp}/)
      context = { druid:, result_path: a_string_matching(/.*#{result_file_path_regexp}/), failure_messages: }
      expect(Honeybadger).to have_received(:notify).with('Found failed OCR results', context:)
    end
  end
end
