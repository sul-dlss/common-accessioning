# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::TextExtraction::Ocr do
  let(:ocr) { described_class.new(cocina_object:, workflow_context:) }
  let(:object_type) { 'https://cocina.sul.stanford.edu/models/image' }
  let(:workflow_context) { {} }
  let(:structural) { instance_double(Cocina::Models::DROStructural, contains: [first_fileset, second_fileset]) }
  let(:first_fileset) { instance_double(Cocina::Models::FileSet, type: 'https://cocina.sul.stanford.edu/models/resources/document', structural: first_fileset_structural) }
  let(:second_fileset) { instance_double(Cocina::Models::FileSet, type: 'https://cocina.sul.stanford.edu/models/resources/image', structural: second_fileset_structural) }
  let(:first_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [pdf_file]) }
  let(:second_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [jpg_file, tif_file, text_file]) }
  let(:pdf_file) { instance_double(Cocina::Models::File, administrative: sdr_info, hasMimeType: 'application/pdf', filename: 'file1.pdf') }
  let(:jpg_file) { instance_double(Cocina::Models::File, administrative: sdr_info, hasMimeType: 'image/jpeg', filename: 'file2.jpg') }
  let(:tif_file) { instance_double(Cocina::Models::File, administrative: sdr_info, hasMimeType: 'image/tiff', filename: 'file2.tif') }
  let(:text_file) { instance_double(Cocina::Models::File, administrative: sdr_info, hasMimeType: 'text/plain', filename: 'file3.txt') }
  let(:sdr_info) { instance_double(Cocina::Models::FileAdministrative, sdrPreserve: true) }

  describe '#possible?' do
    context 'when the object is not a DRO' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO, dro?: false, type: object_type) }

      it 'returns false' do
        expect(ocr.possible?).to be false
      end
    end

    context 'when the object is a DRO' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO, dro?: true, type: object_type, structural:) }

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
          expect(ocr.required?).to be false
        end
      end
    end
  end

  describe '#required?' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, dro?: true, type: object_type) }

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

    context 'when workflow context is emptye' do
      let(:workflow_context) { {} }

      it 'returns false' do
        expect(ocr.required?).to be false
      end
    end
  end

  describe '#filenames_to_ocr' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, structural:, type: object_type) }

    it 'returns a list of filenames that should be OCRed' do
      expect(ocr.send(:filenames_to_ocr)).to eq(['file2.tif'])
    end
  end

  describe '#ocr_files' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, structural:, type: 'https://cocina.sul.stanford.edu/models/document') }

    it 'returns a list of all filenames' do
      expect(ocr.send(:ocr_files)).to eq([pdf_file])
    end
  end
end
