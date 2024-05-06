# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::TextExtraction::Ocr do
  let(:ocr) { described_class.new(cocina_object:, workflow_context:) }
  let(:object_type) { 'https://cocina.sul.stanford.edu/models/image' }
  let(:workflow_context) { {} }

  describe '#required?' do
    context 'when the object is not a DRO' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO, dro?: false, type: object_type) }
      let(:workflow_context) { { 'runOCR' => true } }

      it 'returns false even if context includes runOCR' do
        expect(ocr.required?).to be false
      end
    end

    context 'when the object is a DRO' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO, dro?: true, type: object_type) }

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
      end
    end
  end
end
