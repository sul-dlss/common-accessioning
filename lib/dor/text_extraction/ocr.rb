# frozen_string_literal: true

module Dor
  module TextExtraction
    # Determine if OCR is required and possible for a given object
    class Ocr
      attr_reader :cocina_object, :workflow_context

      def initialize(params = {})
        @cocina_object = params[:cocina_object]
        @workflow_context = params[:workflow_context]
      end

      def possible?
        # only items can be OCR'd
        return false unless cocina_object.dro?

        # only specific content types can be OCR'd
        return false unless allowed_object_types.include? cocina_object.type

        # check to be sure there are actually files to be OCRed
        return false unless filenames_to_ocr.any?

        # TODO: check for any files that have "manuallyCorrected" in cocina structural (then skip)

        true
      end

      def required?
        # checks if user has indicated that OCR should be run (set as workflow_context)
        workflow_context['runOCR'] || false
      end

      private

      # return a list of filenames that should be OCR'd
      # iterate over all files in cocina_object.structural.contains, looking at mimetypes
      # return a list of filenames that are correct mimetype
      def filenames_to_ocr
        ocr_files.map(&:filename)
      end

      # iterate through cocina strutural contains and return all File objects
      def ocr_files
        [].tap do |files|
          matchtype = cocina_object.type == 'https://cocina.sul.stanford.edu/models/book' ? 'page' : cocina_object.type.split('/')[-1]
          cocina_object.structural.contains.each do |fileset|
            next unless fileset.type.include?(matchtype)

            files << ocr_file(fileset)
          end
        end
      end

      def ocr_file(fileset)
        perservedfiles = fileset.structural.contains.select { |file| file.administrative.sdrPreserve && allowed_mimetypes.include?(file.hasMimeType) }
        return perservedfiles[0] if perservedfiles.one?

        perservedfiles = perservedfiles.sort_by { |pfile| allowed_mimetypes.index(pfile.hasMimeType) }
        perservedfiles[0]
      end

      # TODO: refine list of allowed mimetypes for OCR
      # TODO: may use ordering of mimetypes to preferentially select files for OCR
      # defines the mimetypes types for which files for which OCR can possibly be run
      def allowed_mimetypes
        %w[
          image/tiff
          image/jpeg
          image/jp2
          application/pdf
        ]
      end

      # TODO: refine list of allowed object types for OCR
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
