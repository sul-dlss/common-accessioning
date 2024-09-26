# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Ocr::FetchFiles do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }
  let(:ocr) { instance_double(Dor::TextExtraction::Ocr, abbyy_input_path:, filenames_to_ocr: ['file1.txt', 'file2.pdf']) }
  let(:cocina_model) { build(:dro, id: druid).new(structural: {}, type: object_type, access: { view: 'world' }) }
  let(:object_type) { 'https://cocina.sul.stanford.edu/models/image' }
  let(:file_fetcher) { instance_double(Dor::TextExtraction::FileFetcher, write_file_with_retries: written) }
  let(:dsa_object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model, update: true)
  end
  let(:workflow_client) do
    instance_double(Dor::Workflow::Client, process: workflow_process, workflow_status: 'waiting')
  end
  let(:workflow_process) do
    instance_double(Dor::Workflow::Response::Process, lane_id: 'lane1', context: { 'runOCR' => true })
  end
  let(:abbyy_input_path) { File.join(Settings.sdr.abbyy.local_ticket_path, druid) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(dsa_object_client)
    allow(LyberCore::WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(Dor::TextExtraction::FileFetcher).to receive(:new).and_return(file_fetcher)
    allow(Dor::TextExtraction::Ocr).to receive(:new).and_return(ocr)
  end

  context 'when fetching files is successful' do
    let(:written) { true }

    it 'calls the write_file_with_retries method with correct files' do
      expect(perform).to eq ['file1.txt', 'file2.pdf']
      expect(file_fetcher).to have_received(:write_file_with_retries).with(filename: 'file1.txt', location: Pathname.new("#{abbyy_input_path}/file1.txt"), max_tries: 3).once
      expect(file_fetcher).to have_received(:write_file_with_retries).with(filename: 'file2.pdf', location: Pathname.new("#{abbyy_input_path}/file2.pdf"), max_tries: 3).once
    end
  end

  context 'when fetching files fails' do
    let(:written) { false }

    it 'raises an exception' do
      expect { perform }.to raise_error(RuntimeError, 'Unable to fetch file1.txt for druid:bb222cc3333')
      expect(file_fetcher).to have_received(:write_file_with_retries).with(filename: 'file1.txt', location: Pathname.new("#{abbyy_input_path}/file1.txt"), max_tries: 3).once
    end
  end
end
