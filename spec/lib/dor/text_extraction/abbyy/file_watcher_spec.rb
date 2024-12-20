# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::Abbyy::FileWatcher do
  include_context 'with abbyy dir'

  let(:bare_druid) { 'ab123cd4567' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:logger) { instance_double(Logger) }
  let(:workflow_updater) { instance_double(Dor::TextExtraction::WorkflowUpdater) }
  let(:object_client) { instance_double(Dor::Services::Client::Object) }
  let(:events_client) { instance_double(Dor::Services::Client::Events) }
  let(:listener_options) { { force_polling: true } }
  let(:file_watcher) { described_class.new(logger:, listener_options:) }

  before do
    allow(Settings.sdr.abbyy).to receive_messages(
      local_result_path: abbyy_result_xml_path,
      local_exception_path: abbyy_exceptions_path
    )
    allow(Dor::TextExtraction::WorkflowUpdater).to receive(:new).and_return(workflow_updater)
    allow(Honeybadger).to receive(:notify)
    allow(Dor::Services::Client).to receive(:configure)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(workflow_updater).to receive(:mark_ocr_create_errored)
    allow(workflow_updater).to receive(:mark_ocr_create_completed)
    allow(object_client).to receive(:events).and_return(events_client)
    allow(events_client).to receive(:create)
    allow(logger).to receive(:info)
  end

  context 'when a succesful result is created' do
    let(:output_path) { File.join(abbyy_output_path, bare_druid) }
    let(:result_contents) do
      <<~XML
        <OutputDocuments ExportFormat="ALTO" OutputLocation="#{output_path}">
          <FileName>#{bare_druid}.xml</FileName>
        </OutputDocuments>
      XML
    end
    let(:alto_contents) { File.read(File.absolute_path('spec/fixtures/ocr/bb222cc3333_abbyy_alto.xml')) }

    before do
      file_watcher.start
      copy_abbyy_alto(output_path:, druid: bare_druid, contents: alto_contents)
      create_abbyy_result(abbyy_result_xml_path, druid: bare_druid, contents: result_contents)
      sleep(1) # Allow enough time to poll the filesystem
      file_watcher.stop
    end

    it 'updates the OCR workflow' do
      expect(workflow_updater).to have_received(:mark_ocr_create_completed).with(druid)
    end

    it 'logs the success' do
      expect(logger).to have_received(:info).with(/Found successful OCR results for #{druid} at .*#{bare_druid}.xml.result.xml/)
    end

    it 'publishes an event' do
      expect(events_client).to have_received(:create).with(
        {
          type: 'ocr_success',
          data: a_hash_including({ software_name: 'ABBYY FineReader Server', software_version: '14.0' })
        }
      )
    end
  end

  context 'when an exception result is created' do
    # We use a regex to match the result file path because it's in a containing temp directory for which we don't know the path
    let(:result_file_path_regexp) { Regexp.escape("#{abbyy_exceptions_path}/#{bare_druid}.xml.result.xml") }
    let(:failure_messages_regexp) { Regexp.escape(failure_messages.join('; ')) }
    let(:failure_messages) { ['Error one', 'Error two'] }
    let(:errors_xml) do
      <<~XML
        <Message Type="Error"><Text>#{failure_messages[0]}</Text></Message>
        <Message Type="Error"><Text>#{failure_messages[1]}</Text></Message>
      XML
    end

    before do
      file_watcher.start
      create_abbyy_result(abbyy_exceptions_path, druid: bare_druid, success: false, contents: errors_xml)
      sleep(1) # Allow enough time to poll the filesystem
      file_watcher.stop
    end

    it 'updates the OCR workflow' do
      expect(workflow_updater).to have_received(:mark_ocr_create_errored).with(druid, error_msg: "Error one\nError two")
    end

    it 'publishes an event' do
      expect(events_client).to have_received(:create).with(
        {
          type: 'ocr_errored',
          data: a_hash_including({ software_name: 'ABBYY FineReader Server', errors: failure_messages })
        }
      )
    end

    it 'logs the failure messages' do
      expect(logger).to have_received(:info).with(/Found failed OCR results for #{druid} at .*#{result_file_path_regexp}: #{failure_messages_regexp}/)
    end

    it 'notifies honeybadger' do
      expect(Honeybadger).to have_received(:notify).with(
        'Found failed OCR results',
        context: {
          druid:,
          result_path: a_string_matching(/.*#{result_file_path_regexp}/),
          failure_messages:
        }
      )
    end
  end
end
