# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::TextExtraction::Ocr do
  let(:ocr) { described_class.new(cocina_object:, workflow_context:) }
  let(:object_type) { 'https://cocina.sul.stanford.edu/models/image' }
  let(:workflow_context) { {} }
  let(:structural) { instance_double(Cocina::Models::DROStructural, contains: [first_fileset, second_fileset]) }
  let(:first_fileset) { instance_double(Cocina::Models::FileSet, structural: first_fileset_structural) }
  let(:second_fileset) { instance_double(Cocina::Models::FileSet, structural: second_fileset_structural) }
  let(:first_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [pdf_file]) }
  let(:second_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [jpg_file, text_file]) }
  let(:pdf_file) { instance_double(Cocina::Models::File, hasMimeType: 'application/pdf', filename: 'file1.pdf') }
  let(:jpg_file) { instance_double(Cocina::Models::File, hasMimeType: 'image/jpeg', filename: 'file2.jpg') }
  let(:text_file) { instance_double(Cocina::Models::File, hasMimeType: 'text/plain', filename: 'file3.txt') }

  describe '#required?' do
    context 'when the object is not a DRO' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO, dro?: false, type: object_type) }
      let(:workflow_context) { { 'runOCR' => true } }

      it 'returns false even if context includes runOCR' do
        expect(ocr.required?).to be false
      end
    end

    context 'when the object is a DRO' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO, dro?: true, type: object_type, structural:) }

      context 'when workflow context does not include runOCR' do
        it 'returns false' do
          expect(ocr.required?).to be false
        end
      end

      context 'when the object type is one that does not require OCR' do
        let(:object_type) { 'https://cocina.sul.stanford.edu/models/media' }

        it 'returns false' do
          expect(ocr.required?).to be false
        end
      end

      context 'when workflow context includes runOCR' do
        let(:workflow_context) { { 'runOCR' => true } }

        it 'returns true' do
          expect(ocr.required?).to be true
        end

        context 'when the object type is one that does not require OCR' do
          let(:object_type) { 'https://cocina.sul.stanford.edu/models/media' }

          it 'returns false' do
            expect(ocr.required?).to be false
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
  end

  describe '#filenames_to_ocr' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, structural:) }

    it 'returns a list of filenames that should be OCRed' do
      expect(ocr.filenames_to_ocr).to eq(['file1.pdf', 'file2.jpg'])
    end
  end

  describe '#cocina_files' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, structural:) }

    it 'returns a list of all filenames' do
      expect(ocr.cocina_files).to eq([pdf_file, jpg_file, text_file])
    end
  end
end
