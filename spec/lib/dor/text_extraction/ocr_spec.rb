# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::TextExtraction::Ocr do
  let(:ocr) { described_class.new(cocina_object:, workflow_context:) }
  let(:ticket) { Dor::TextExtraction::Abbyy::Ticket.new(filepaths: [], druid:) }
  let(:object_type) { 'https://cocina.sul.stanford.edu/models/image' }
  let(:workflow_context) { {} }
  let(:structural) { instance_double(Cocina::Models::DROStructural, contains: [first_fileset, second_fileset]) }
  let(:first_fileset) { instance_double(Cocina::Models::FileSet, type: 'https://cocina.sul.stanford.edu/models/resources/document', structural: first_fileset_structural) }
  let(:second_fileset) { instance_double(Cocina::Models::FileSet, type: 'https://cocina.sul.stanford.edu/models/resources/image', structural: second_fileset_structural) }
  let(:first_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [pdf_file]) }
  let(:second_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [jpg_file, tif_file, text_file]) }
  let(:pdf_file) { build_file(true, 'file1.pdf') }
  let(:jpg_file) { build_file(true, 'file2.jpg') }
  let(:tif_file) { build_file(true, 'file2.tif') }
  let(:text_file) { build_file(true, 'file3.txt') }
  let(:druid) { 'druid:bc123df4567' }

  def build_file(sdr_peserve, filename)
    extension = File.extname(filename)
    mimetype = { '.pdf' => 'application/pdf', '.tif' => 'image/tiff', '.jpg' => 'image/jpeg', '.txt' => 'text/plain' }
    sdr_value = instance_double(Cocina::Models::FileAdministrative, sdrPreserve: sdr_peserve)
    instance_double(Cocina::Models::File, administrative: sdr_value, hasMimeType: mimetype[extension], filename:)
  end

  describe '#possible?' do
    context 'when the object is not a DRO' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: false, type: object_type) }

      it 'returns false' do
        expect(ocr.possible?).to be false
      end
    end

    context 'when the object is a DRO' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: true, type: object_type, structural:) }

      context 'when the object type is one that does not require OCR' do
        let(:object_type) { 'https://cocina.sul.stanford.edu/models/media' }

        it 'returns false' do
          expect(ocr.possible?).to be false
        end
      end

      context 'when the object has no files that can be OCRed' do
        let(:first_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [text_file]) }
        let(:second_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [text_file, text_file]) }

        it 'returns false' do
          expect(ocr.possible?).to be false
        end
      end

      context 'when the object has files that can be OCRed' do
        let(:first_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [jpg_file]) }

        it 'returns true' do
          expect(ocr.possible?).to be true
        end
      end
    end
  end

  describe '#required?' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: true, type: object_type) }

    context 'when workflow context includes runOCR as true' do
      let(:workflow_context) { { 'runOCR' => true } }

      it 'returns true' do
        expect(ocr.required?).to be true
      end
    end

    context 'when workflow context includes runOCR as false' do
      let(:workflow_context) { { 'runOCR' => false } }

      it 'returns false' do
        expect(ocr.required?).to be false
      end
    end

    context 'when workflow context is empty' do
      let(:workflow_context) { {} }

      it 'returns false' do
        expect(ocr.required?).to be false
      end
    end
  end

  describe '#filenames_to_ocr' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, structural:, type: object_type) }

    it 'returns a list of filenames that should be OCRed' do
      expect(ocr.send(:filenames_to_ocr)).to eq(['file2.tif'])
    end

    context 'when tif file is not in preservation' do
      let(:tif_file) { build_file(false, 'file2.tif') }

      it 'returns the jpg file' do
        expect(ocr.send(:filenames_to_ocr)).to eq(['file2.jpg'])
      end
    end
  end

  describe '#ocr_files' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, structural:, type: 'https://cocina.sul.stanford.edu/models/document') }

    it 'returns a list of all filenames' do
      expect(ocr.send(:ocr_files)).to eq([pdf_file])
    end
  end

  describe '#cleanup' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: true, type: object_type, structural:) }

    # start with a clean slate, we will create directories and files to cleanup for each scenario
    before do
      FileUtils.rm_rf(ocr.abbyy_input_path)
      FileUtils.rm_rf(ocr.abbyy_output_path)
      FileUtils.rm_f(ticket.file_path)
    end

    context 'when no input or output folders or xml file' do
      it 'does nothing' do
        [ocr.abbyy_input_path, ocr.abbyy_output_path, ticket.file_path].each { |path| expect(File.exist?(path)).to be false }
        expect(ocr.cleanup).to be true
      end
    end

    context 'when input folder is not empty' do
      before do
        FileUtils.mkdir_p(ocr.abbyy_input_path)
        FileUtils.mkdir_p(ocr.abbyy_output_path)
        FileUtils.touch(File.join(ocr.abbyy_input_path, 'file1.txt'))
      end

      it 'raises an error' do
        expect { ocr.cleanup }.to raise_error("#{ocr.abbyy_input_path} is not empty")
        expect(Dir.exist?(ocr.abbyy_input_path)).to be true
        expect(Dir.exist?(ocr.abbyy_output_path)).to be true
      end
    end

    context 'when output folder is not empty' do
      before do
        FileUtils.mkdir_p(ocr.abbyy_input_path)
        FileUtils.mkdir_p(ocr.abbyy_output_path)
        FileUtils.touch(File.join(ocr.abbyy_output_path, 'file1.txt'))
      end

      it 'raises an error but still deletes the input path' do
        expect { ocr.cleanup }.to raise_error("#{ocr.abbyy_output_path} is not empty")
        expect(Dir.exist?(ocr.abbyy_input_path)).to be false
        expect(Dir.exist?(ocr.abbyy_output_path)).to be true
      end
    end

    context 'when input and output folders are empty and xml ticket file exists' do
      before do
        FileUtils.mkdir_p(ocr.abbyy_input_path)
        FileUtils.mkdir_p(ocr.abbyy_output_path)
        FileUtils.touch(ticket.file_path)
      end

      it 'removes both folders and the XML ticket file' do
        [ocr.abbyy_input_path, ocr.abbyy_output_path, ticket.file_path].each { |path| expect(File.exist?(path)).to be true }
        ocr.cleanup
        [ocr.abbyy_input_path, ocr.abbyy_output_path, ticket.file_path].each { |path| expect(File.exist?(path)).to be false }
      end
    end
  end
end
