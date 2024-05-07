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
        # only items can be OCR'd
        return false unless cocina_object.dro?

        # only specific content types can be OCR'd
        return false unless allowed_object_types.include? cocina_object.type

        # checks if user has indicated that OCR should be run (set as workflow_context)
        return false unless workflow_context['runOCR']

        # check to be sure there are actually files to be OCRed
        return false unless filenames_to_ocr.any?

        # TODO: check for any files that have "manuallyCorrected" in cocina structural (then skip)

        true
      end

      # return a list of filenames that should be OCR'd
      # iterate over all files in cocina_object.structural.contains, looking at mimetypes
      # return a list of filenames that are correct mimetype
      def filenames_to_ocr
        cocina_files.select { |file| allowed_mimetypes.include? file.hasMimeType }.map(&:filename)
      end

      # iterate through cocina strutural contains and return all File objects
      def cocina_files
        [].tap do |files|
          cocina_object.structural.contains.each do |fileset|
            fileset.structural.contains.each do |file|
              files << file
            end
          end
        end
      end

      private

      # defines the mimetypes types for which files for which OCR can possibly be run
      def allowed_mimetypes
        %w[
          application/pdf
          image/tiff
          image/jp2
          image/jpeg
        ]
      end

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
