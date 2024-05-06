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

        return false unless allowed_object_types.include? cocina_object.type

        # user has indicated that OCR should be run (set as workflow_context)
        return false unless workflow_context['runOCR']

        # TODO: check for required input files for OCR? (skip if none found) e.g. by mimetype
        # Tterate over all files in cocina_object.structural.contains, looking at mimetypes
        # if there are no files that are correct mimetype

        # TODO: check for any files that have "manuallyCorrected" in cocina structural (then skip)

        true
      end

      private

      # defines the object types for which OCR can possibly be run
      def allowed_object_types
        %w[
          https://cocina.sul.stanford.edu/models/book
          https://cocina.sul.stanford.edu/models/document
          https://cocina.sul.stanford.edu/models/image
        ]
      end
    end
  end
end
