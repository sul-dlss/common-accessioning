# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::TextExtraction::Ocr do
  let(:ocr) { described_class.new(cocina_object:, workflow_context:) }

  describe '#required?' do
    context 'when the object is not a DRO' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO, dro?: false) }
      let(:workflow_context) { { 'runOCR' => true } }

      it 'returns false even if context includes runOCR' do
        expect(ocr.required?).to be false
      end
    end

    context 'when the object is a DRO' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO, dro?: true) }

      context 'when workflow context does not include runOCR' do
        let(:workflow_context) { {} }

        it 'returns false' do
          expect(ocr.required?).to be false
        end
      end

      context 'when workflow context includes runOCR' do
        let(:workflow_context) { { 'runOCR' => true } }

        it 'returns false' do
          expect(ocr.required?).to be true
        end
      end
    end
  end
end
