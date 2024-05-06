# frozen_string_literal: true

module Dor
  module TextExtraction
    # Determine if OCR is required for a given object
    class Ocr
      attr_reader :cocina_object, :workflow_context

      def initialize(params = {})
        @cocina_object = params[:cocina_object]
        @workflow_context = params[:workflow_context]
      end

      def required?
        return false unless cocina_object.dro? # only items can be OCR'd

        # TODO: check for specific content types that should be OCR'd? (skip if invalid object content type)
        # TODO: check for required input files for OCR? (skip if none found)
        # TODO: check for any files that have "manuallyCorrected" in cocina structural (then skip)

        # user has indicated that OCR should be run (set as workflow_context)
        return false unless workflow_context['runOCR']

        true
      end
    end
  end
end
