# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::SpeechToText::FetchFiles do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:bb222cc3333' }
  let(:bare_druid) { 'bb222cc3333' }
  let(:robot) { described_class.new }
  let(:file_fetcher) { instance_double(Dor::TextExtraction::FileFetcher, write_file_with_retries: written) }
  let(:stt) { instance_double(Dor::TextExtraction::SpeechToText, filenames_to_stt: ['file1.mov', 'file2.mp3']) }
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

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(dsa_object_client)
    allow(LyberCore::WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(Dor::TextExtraction::FileFetcher).to receive(:new).and_return(file_fetcher)
    allow(Dor::TextExtraction::SpeechToText).to receive(:new).and_return(stt)
  end

  context 'when fetching files is successful' do
    let(:written) { true }

    it 'calls the write_file_with_retries method with correct files' do
      expect(perform).to eq ['file1.mov', 'file2.mp3']
      expect(file_fetcher).to have_received(:write_file_with_retries).with(filename: "#{bare_druid}/file1.mov", bucket: Settings.aws.base_s3_bucket, max_tries: 3).once
      expect(file_fetcher).to have_received(:write_file_with_retries).with(filename: "#{bare_druid}/file2.mp3", bucket: Settings.aws.base_s3_bucket, max_tries: 3).once
    end
  end

  context 'when fetching files fails' do
    let(:written) { false }

    it 'raises an exception' do
      expect { perform }.to raise_error(RuntimeError, 'Unable to fetch file1.mov for druid:bb222cc3333')
      expect(file_fetcher).to have_received(:write_file_with_retries).with(filename: "#{bare_druid}/file1.mov", bucket: Settings.aws.base_s3_bucket, max_tries: 3).once
    end
  end
end
