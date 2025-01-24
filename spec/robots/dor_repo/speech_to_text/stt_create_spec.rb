# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::SpeechToText::SttCreate do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:bb222cc3333' }
  let(:bare_druid) { 'bb222cc3333' }
  let(:robot) { described_class.new }
  let(:aws_s3_client) { instance_double(Aws::S3::Client) }
  let(:aws_batch_client) { instance_double(Aws::Batch::Client) }
  let(:filenames_to_stt) { ['file1.mov', 'file2.mp3'] }
  let(:stt) { instance_double(Dor::TextExtraction::SpeechToText, job_id:, filenames_to_stt:) }
  let(:cocina_model) { build(:dro, id: druid).new(structural: {}, type: object_type, access: { view: 'world' }) }
  let(:object_type) { Cocina::Models::ObjectType.media }
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
  let(:media) { [{ name: "#{job_id}/#{filenames_to_stt[0]}", options: { language: 'en' } }, { name: "#{job_id}/#{filenames_to_stt[1]}", options: { language: 'es' } }] }
  let(:list_objects) { instance_double(Aws::S3::Types::ListObjectsOutput, contents: [mov_object, mp3_object]) }
  let(:job_response) { instance_double(Aws::Batch::Types::SubmitJobResponse) }
  let(:mov_object) { instance_double(Aws::S3::Types::Object, key: media[0][:name]) }
  let(:mp3_object) { instance_double(Aws::S3::Types::Object, key: media[1][:name]) }

  before do
    allow(Aws::S3::Client).to receive(:new).and_return(aws_s3_client)
    allow(Aws::Batch::Client).to receive(:new).and_return(aws_batch_client)
    allow(Dor::Services::Client).to receive(:object).and_return(dsa_object_client)
    allow(Dor::TextExtraction::SpeechToText).to receive(:new).and_return(stt)
    allow(LyberCore::WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(aws_s3_client).to receive(:list_objects).and_return(list_objects)
    allow(aws_batch_client).to receive(:submit_job).and_return(job_response)
    allow(stt).to receive(:language_tag).with(filenames_to_stt[0]).and_return('en')
    allow(stt).to receive(:language_tag).with(filenames_to_stt[1]).and_return('es')
  end

  context 'when the message is sent successfully' do
    let(:message_body) { { id: job_id, druid:, media: }.merge(Settings.speech_to_text.whisper.to_h).to_json }

    it 'sends AWS Batch job but does not complete the step' do
      expect(perform.status).to eq 'noop'
      expect(aws_batch_client).to have_received(:submit_job).with(
        {
          job_name: job_id,
          job_definition: Settings.aws.speech_to_text.batch_job_definition,
          job_queue: Settings.aws.speech_to_text.batch_job_queue,
          parameters: { job: message_body }
        }
      ).once
    end
  end

  context 'when the message is not sent successfully' do
    before do
      allow(aws_batch_client).to receive(:submit_job).and_raise(Aws::Batch::Errors::ServiceError.new(nil, 'blam'))
      allow(Honeybadger).to receive(:notify)
    end

    it 'raises an exception and alerts HB' do
      expect { perform }.to raise_error(RuntimeError, 'Error sending Batch job: blam')
      expect(Honeybadger).to have_received(:notify).with('Problem sending Batch job to AWS for SpeechToText', context: { druid:, job_id:, error: instance_of(Aws::Batch::Errors::ServiceError) }).once
    end
  end

  context 'when a file has no language tag' do
    let(:message_body) { { id: job_id, druid:, media: [{ name: "#{job_id}/#{filenames_to_stt[0]}" }] }.merge(Settings.speech_to_text.whisper.to_h).to_json }

    before do
      allow(stt).to receive(:language_tag).with(filenames_to_stt[0]).and_return(nil)
      allow(aws_batch_client).to receive(:submit_job).and_return(true)
      allow(aws_s3_client).to receive(:list_objects).and_return(instance_double(Aws::S3::Types::ListObjectsOutput, contents: [mov_object]))
    end

    it 'sends Batch job without language options' do
      expect(perform.status).to eq 'noop'
      expect(aws_batch_client).to have_received(:submit_job).once
    end
  end
end
