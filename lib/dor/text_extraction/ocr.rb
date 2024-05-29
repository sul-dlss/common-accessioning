# frozen_string_literal: true

module Dor
  module TextExtraction
    # Determine if OCR is required and possible for a given object
    class Ocr
      attr_reader :cocina_object, :workflow_context, :bare_druid

      def initialize(params = {})
        @cocina_object = params[:cocina_object]
        @workflow_context = params[:workflow_context] || {}
        @bare_druid = cocina_object.externalIdentifier.delete_prefix('druid:')
      end

      def abbyy_output_path
        File.join(Settings.sdr.abbyy.local_output_path, bare_druid)
      end

      def abbyy_input_path
        File.join(Settings.sdr.abbyy.local_ticket_path, bare_druid)
      end

      # rubocop:disable Metrics/AbcSize
      def cleanup
        if Dir.exist?(abbyy_input_path)
          raise "#{abbyy_input_path} is not empty" unless Dir.empty?(abbyy_input_path)

          FileUtils.rm_rf(abbyy_input_path)
        end

        return true unless Dir.exist?(abbyy_output_path)

        raise "#{abbyy_output_path} is not empty" unless Dir.empty?(abbyy_output_path)

        FileUtils.rm_rf(abbyy_output_path)

        FileUtils.rm_f(Abbyy::Ticket.new(filepaths: [], druid: cocina_object.externalIdentifier).file_path) # remove XML ticket file
      end
      # rubocop:enable Metrics/AbcSize

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
        # checks if user has indicated that OCR should be run (sent as workflow_context)
        workflow_context['runOCR'] || false
      end

      # return a list of filenames that should be OCR'd
      # iterate over all files in cocina_object.structural.contains, looking at mimetypes
      # return a list of filenames that are correct mimetype
      def filenames_to_ocr
        ocr_files.map(&:filename)
      end

      private

      # iterate through cocina strutural contains and return all File objects for files that need to be OCRed
      def ocr_files
        [].tap do |files|
          cocina_object.structural.contains.each do |fileset|
            next unless fileset.type.include?(matchtype)

            files << ocr_file(fileset)
          end
        end.compact
      end

      # filter down fileset files to those in preservation and are allowedmimetypes
      # if there are more than one allowed mimetype, grab the preferred type
      def ocr_file(fileset)
        perservedfiles = fileset.structural.contains.select { |file| file.administrative.sdrPreserve && allowed_mimetypes.include?(file.hasMimeType) }
        return perservedfiles[0] if perservedfiles.one?

        perservedfiles = perservedfiles.sort_by { |pfile| allowed_mimetypes.index(pfile.hasMimeType) }
        perservedfiles[0]
      end

      # defines the mimetypes types for which files for which OCR can possibly be run
      # preferentially select files for OCR by ordering of mimetypes below
      # TODO: refine list of allowed mimetypes for OCR
      def allowed_mimetypes
        %w[
          image/tiff
          image/jpeg
          image/jp2
          application/pdf
        ]
      end

      # maps the allowed content types to the resource type we will look for files in
      # TODO: refine list of allowed object types for OCR
      def resource_type_mapping
        {
          'https://cocina.sul.stanford.edu/models/book' => 'page',
          'https://cocina.sul.stanford.edu/models/document' => 'document',
          'https://cocina.sul.stanford.edu/models/image' => 'image'
        }
      end

      def matchtype
        resource_type_mapping[cocina_object.type]
      end

      def allowed_object_types
        resource_type_mapping.keys
      end
    end
  end
end
