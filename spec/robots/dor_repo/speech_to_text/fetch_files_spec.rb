# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::SpeechToText::FetchFiles do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:bb222cc3333' }
  let(:bare_druid) { 'bb222cc3333' }
  let(:robot) { described_class.new }
  let(:file_fetcher) { instance_double(Dor::TextExtraction::FileFetcher, write_file_with_retries: written) }
  let(:stt) { instance_double(Dor::TextExtraction::SpeechToText, job_id:, filenames_to_stt: ['file1.mov', 'file2.mp3']) }
  let(:cocina_model) { build(:dro, id: druid).new(structural: {}, type: object_type, access: { view: 'world' }) }
  let(:object_type) { Cocina::Models::ObjectType.media }
  let(:dsa_object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model, update: true)
  end
  let(:process_response) { instance_double(Dor::Services::Response::Process, lane_id: 'lane1', context: { 'runSpeechToText' => true }) }
  let(:workflow_response) { instance_double(Dor::Services::Response::Workflow, process_for_recent_version: process_response) }
  let(:object_workflow) { instance_double(Dor::Services::Client::ObjectWorkflow, find: workflow_response, create: nil) }
  let(:workflow_process) { instance_double(Dor::Services::Client::Process, update: true, update_error: true, status: 'waiting') }
  let(:aws_client) { instance_double(Aws::S3::Client) }
  let(:mov_location) { instance_double(Aws::S3::Object, bucket_name: Settings.aws.speech_to_text.base_s3_bucket, key: "#{job_id}/file1.mov", client: aws_client) }
  let(:mp3_location) { instance_double(Aws::S3::Object, bucket_name: Settings.aws.speech_to_text.base_s3_bucket, key: "#{job_id}/file2.mp3", client: aws_client) }
  let(:job_id) { "#{bare_druid}-v1" }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(dsa_object_client)
    allow(dsa_object_client).to receive(:workflow).with('speechToTextWF').and_return(object_workflow)
    allow(object_workflow).to receive(:process).with('fetch-files').and_return(workflow_process)
    allow(Dor::TextExtraction::FileFetcher).to receive(:new).and_return(file_fetcher)
    allow(Dor::TextExtraction::SpeechToText).to receive(:new).and_return(stt)
    allow(Aws::S3::Client).to receive(:new).and_return(aws_client)
    allow(Aws::S3::Object).to receive(:new).with(bucket_name: Settings.aws.speech_to_text.base_s3_bucket, key: "#{job_id}/file1.mov", client: aws_client).and_return(mov_location)
    allow(Aws::S3::Object).to receive(:new).with(bucket_name: Settings.aws.speech_to_text.base_s3_bucket, key: "#{job_id}/file2.mp3", client: aws_client).and_return(mp3_location)
    allow(stt).to receive(:s3_location).with('file1.mov').and_return("#{job_id}/file1.mov")
    allow(stt).to receive(:s3_location).with('file2.mp3').and_return("#{job_id}/file2.mp3")
  end

  context 'when fetching files is successful' do
    let(:written) { true }

    it 'calls the write_file_with_retries method with correct files' do
      expect(perform).to eq ['file1.mov', 'file2.mp3']
      expect(file_fetcher).to have_received(:write_file_with_retries).with(filename: 'file1.mov', location: mov_location, max_tries: 3).once
      expect(file_fetcher).to have_received(:write_file_with_retries).with(filename: 'file2.mp3', location: mp3_location, max_tries: 3).once
    end
  end

  context 'when fetching files fails' do
    let(:written) { false }

    it 'raises an exception' do
      expect { perform }.to raise_error(RuntimeError, 'Unable to fetch file1.mov for druid:bb222cc3333')
      expect(file_fetcher).to have_received(:write_file_with_retries).with(filename: 'file1.mov', location: mov_location, max_tries: 3).once
    end
  end
end
