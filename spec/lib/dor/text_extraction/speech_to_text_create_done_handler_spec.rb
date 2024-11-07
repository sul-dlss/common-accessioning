# frozen_string_literal: true

describe Dor::TextExtraction::SpeechToTextCreateDoneHandler do
  subject(:handler) { described_class.new(host:, progname:, logger:) }

  let(:host) { 'common-accessioning-test-y.stanford.edu' }
  let(:progname) { 'stt_create_done_handler_spec' }
  let(:logger) { instance_double(Logger, debug: nil, info: nil) }
  let(:bare_druid) { 'bc123df4567' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:workflow_updater) { instance_double(Dor::TextExtraction::WorkflowUpdater, mark_stt_create_completed: nil, mark_stt_create_errored: nil) }
  let(:dor_event_logger) { instance_double(Dor::TextExtraction::DorEventLogger, create_event: nil) }
  let(:whisper_error_msg) { nil }
  let(:done_msg_hash) do
    {
      'id' => "#{bare_druid}-v2",
      'media' => ['bear_breaks_into_home_plays_piano_no_speech.mp4'],
      'finished' => '2024-10-08T16:35:44.959829+00:00',
      'extraction_technical_metadata' => {
        'speech_to_text_extraction_program' => { 'name' => 'whisper', 'version' => '20240930' },
        'effective_options' => { 'fp16' => false },
        'effective_writer_options' => { 'highlight_words' => nil, 'max_line_count' => nil, 'max_line_width' => nil, 'max_words_per_line' => nil },
        'effective_model_name' => 'small'
      }
    }.tap { |done_msg_hash| done_msg_hash.merge!({ 'error' => whisper_error_msg }) if whisper_error_msg.present? }
  end
  let(:done_msg_body) { done_msg_hash.to_json }
  let(:done_msg) { instance_double(Aws::SQS::Types::Message, body: done_msg_body) }
  let(:event_data) { { host:, invoked_by: progname, done_msg_body: done_msg_hash } }

  before do
    allow(Dor::TextExtraction::WorkflowUpdater).to receive(:new).with(logger:).and_return(workflow_updater)
    allow(Dor::TextExtraction::DorEventLogger).to receive(:new).with(logger:).and_return(dor_event_logger)
    handler.process_done_message(done_msg)
  end

  describe '#process_done_message' do
    context 'when there is no error field' do
      it 'creates a DOR event log entry for creation success' do
        expect(dor_event_logger).to have_received(:create_event).with(druid:, type: 'stt-create-success', data: event_data)
      end

      it 'marks the workflow step as completed' do
        expect(workflow_updater).to have_received(:mark_stt_create_completed).with(druid)
      end
    end

    context 'when there is an error field' do
      let(:whisper_error_msg) { 'oh no! there was an unexpected error trying to extract text from speech' }

      it 'creates a DOR event log entry for creation failure' do
        expect(dor_event_logger).to have_received(:create_event).with(druid:, type: 'stt-create-error', data: event_data)
      end

      it 'marks the workflow step as errored' do
        expect(workflow_updater).to have_received(:mark_stt_create_errored).with(druid, error_msg: whisper_error_msg)
      end
    end
  end
end
