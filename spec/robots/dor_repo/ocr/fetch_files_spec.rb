# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Ocr::FetchFiles do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }
  let(:ocr) { instance_double(Dor::TextExtraction::Ocr, abbyy_input_path:, filenames_to_ocr: ['file1.txt', 'file2.pdf']) }
  let(:cocina_model) { build(:dro, id: druid).new(structural: {}, type: object_type, access: { view: 'world' }) }
  let(:object_type) { Cocina::Models::ObjectType.image }
  let(:file_fetcher) { instance_double(Dor::TextExtraction::FileFetcher, write_file_with_retries: fetch_success) }
  let(:fetch_success) { true }
  let(:dsa_object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model, update: true)
  end
  let(:process_response) { instance_double(Dor::Services::Response::Process, lane_id: 'lane1', context: { 'runOCR' => true }) }
  let(:workflow_response) { instance_double(Dor::Services::Response::Workflow, process_for_recent_version: process_response) }
  let(:object_workflow) { instance_double(Dor::Services::Client::ObjectWorkflow, find: workflow_response, create: nil) }
  let(:workflow_process) { instance_double(Dor::Services::Client::Process, update: true, update_error: true, status: 'queued') }
  let(:abbyy_input_path) { File.join(Settings.sdr.abbyy.local_ticket_path, druid) }
  let(:assembly_image) { instance_double(Assembly::Image, image?: false, multi_page?: nil, extract_first_page: nil) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(dsa_object_client)
    allow(dsa_object_client).to receive(:workflow).with('ocrWF').and_return(object_workflow)
    allow(object_workflow).to receive(:process).with('fetch-files').and_return(workflow_process)
    allow(Dor::TextExtraction::FileFetcher).to receive(:new).and_return(file_fetcher)
    allow(Dor::TextExtraction::Ocr).to receive(:new).and_return(ocr)
    allow(Assembly::Image).to receive(:new).and_return(assembly_image)
  end

  context 'when fetching files is successful' do
    let(:fetch_success) { true }

    it 'calls the write_file_with_retries method with correct files' do
      expect(perform).to eq ['file1.txt', 'file2.pdf']
      expect(file_fetcher).to have_received(:write_file_with_retries).with(filename: 'file1.txt', location: Pathname.new("#{abbyy_input_path}/file1.txt"), max_tries: 3).once
      expect(file_fetcher).to have_received(:write_file_with_retries).with(filename: 'file2.pdf', location: Pathname.new("#{abbyy_input_path}/file2.pdf"), max_tries: 3).once
    end
  end

  context 'when fetching files fails' do
    let(:fetch_success) { false }

    it 'raises an exception' do
      expect { perform }.to raise_error(RuntimeError, 'Unable to fetch file1.txt for druid:bb222cc3333')
      expect(file_fetcher).to have_received(:write_file_with_retries).with(filename: 'file1.txt', location: Pathname.new("#{abbyy_input_path}/file1.txt"), max_tries: 3).once
    end
  end

  describe '#replace_multipage_tiff' do
    subject(:replace_multipage_tiff) { robot.send(:replace_multipage_tiff, location) }

    let(:location) { Pathname.new(File.join(abbyy_input_path, 'test_image.tif')) }

    context 'when the file is not an image' do
      before do
        allow(assembly_image).to receive(:image?).and_return(false)
      end

      it 'does not extract or replace the file' do
        replace_multipage_tiff
        expect(assembly_image).not_to have_received(:multi_page?)
      end
    end

    context 'when the file is an image but not multi-page' do
      before do
        allow(assembly_image).to receive_messages(image?: true, multi_page?: false)
      end

      it 'does not extract or replace the file' do
        replace_multipage_tiff
        expect(assembly_image).not_to have_received(:extract_first_page)
      end
    end

    context 'when the file is a multi-page TIFF' do
      let(:first_page_filepath) { File.join(abbyy_input_path, 'test_image_first_page.tif') }

      before do
        allow(assembly_image).to receive_messages(image?: true, multi_page?: true, filename_without_ext: 'test_image', filename: 'test_image.tif', ext: '.tif')
        allow(assembly_image).to receive(:extract_first_page).with(first_page_filepath).and_return(true)
        allow(FileUtils).to receive(:mv)
      end

      it 'extracts the first page and replaces the original file' do
        replace_multipage_tiff
        expect(assembly_image).to have_received(:extract_first_page).with(first_page_filepath)
        expect(FileUtils).to have_received(:mv).with(first_page_filepath, location.to_s, force: true)
      end

      context 'when extracting the first page fails' do
        before do
          allow(assembly_image).to receive(:extract_first_page).and_return(false)
        end

        it 'raises an error' do
          expect { replace_multipage_tiff }.to raise_error(RuntimeError, 'Failed to extract first page of multi-page TIFF test_image.tif')
        end
      end
    end
  end
end
