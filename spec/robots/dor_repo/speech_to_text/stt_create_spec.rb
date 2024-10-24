# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::SpeechToText::SttCreate do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:bb222cc3333' }
  let(:bare_druid) { 'bb222cc3333' }
  let(:robot) { described_class.new }
  let(:aws_client) { instance_double(Aws::SQS::Client) }
  let(:aws_s3_client) { instance_double(Aws::S3::Client) }
  let(:stt) { instance_double(Dor::TextExtraction::SpeechToText, job_id:, filenames_to_stt: ['file1.mov', 'file2.mp3']) }
  let(:cocina_model) { build(:dro, id: druid).new(structural: {}, type: object_type, access: { view: 'world' }) }
  let(:object_type) { 'https://cocina.sul.stanford.edu/models/media' }
  let(:dsa_object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model, update: true)
  end
  let(:workflow_client) do
    instance_double(Dor::Workflow::Client, process: workflow_process, workflow_status: 'waiting')
  end
  let(:workflow_process) do
    instance_double(Dor::Workflow::Response::Process, lane_id: 'lane1', context: { 'runSpeechToText' => true })
  end
  let(:job_id) { "#{bare_druid}-v1" }
  let(:media) { ["#{job_id}/file1.mov", "#{job_id}/file2.mp3"] }
  let(:list_objects) { instance_double(Aws::S3::Types::ListObjectsOutput, contents: [mov_object, mp3_object]) }
  let(:mov_object) { instance_double(Aws::S3::Types::Object, key: media[0]) }
  let(:mp3_object) { instance_double(Aws::S3::Types::Object, key: media[1]) }

  before do
    allow(Aws::S3::Client).to receive(:new).and_return(aws_s3_client)
    allow(Aws::SQS::Client).to receive(:new).and_return(aws_client)
    allow(Dor::Services::Client).to receive(:object).and_return(dsa_object_client)
    allow(Dor::TextExtraction::SpeechToText).to receive(:new).and_return(stt)
    allow(LyberCore::WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(aws_s3_client).to receive(:list_objects).and_return(list_objects)
  end

  context 'when the message is sent successfully' do
    let(:message_body) { { id: job_id, druid:, media:, options: { model: 'large-v3', beam_size: 10, writer: { max_line_width: 42, max_line_count: 1 } } }.to_json }

    before do
      allow(aws_client).to receive(:send_message).with({ queue_url: Settings.aws.speech_to_text.sqs_todo_queue_url, message_body: }).and_return(true)
    end

    it 'sends SQS messages but does not complete the step' do
      expect(perform.status).to eq 'noop'
      expect(aws_client).to have_received(:send_message).with({ queue_url: Settings.aws.speech_to_text.sqs_todo_queue_url, message_body: }).once
    end
  end

  context 'when the message is not sent successfully' do
    before do
      allow(aws_client).to receive(:send_message).and_raise(Aws::SQS::Errors::ServiceError.new(nil, 'blam'))
      allow(Honeybadger).to receive(:notify)
    end

    it 'raises an exception and alerts HB' do
      expect { perform }.to raise_error(RuntimeError, 'Error sending SQS message: blam')
      expect(Honeybadger).to have_received(:notify).with('Problem sending SQS Message to AWS for SpeechToText', context: { druid:, job_id:, error: instance_of(Aws::SQS::Errors::ServiceError) }).once
    end
  end
end
