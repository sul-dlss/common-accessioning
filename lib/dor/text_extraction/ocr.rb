# frozen_string_literal: true

module Dor
  module TextExtraction
    # Determine if OCR is required and possible for a given object
    # rubocop:disable Metrics/ClassLength
    class Ocr
      attr_reader :cocina_object, :workflow_context, :bare_druid, :logger

      def initialize(cocina_object:, workflow_context: {}, logger: nil)
        @cocina_object = cocina_object
        @workflow_context = workflow_context
        @bare_druid = cocina_object.externalIdentifier.delete_prefix('druid:')
        @logger = logger || Logger.new($stdout)
      end

      def abbyy_output_path
        File.join(Settings.sdr.abbyy.local_output_path, bare_druid)
      end

      def abbyy_input_path
        File.join(Settings.sdr.abbyy.local_ticket_path, bare_druid)
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def cleanup
        raise "#{abbyy_input_path} is not empty" if Dir.exist?(abbyy_input_path) && !Dir.empty?(abbyy_input_path)

        tries = 0
        max_tries = 5
        begin
          cleanup_input_folder
          cleanup_output_folder
          cleanup_xml_ticket
          cleanup_abbyy_results
          cleanup_abbyy_exceptions
        rescue SystemCallError => e # SystemCallError is the superclass of all errors raised by system calls, such as Errno::ENOENT from FileUtils.rm_r
          tries += 1
          sleep(3**tries)

          logger.info "Retry #{tries} for ocr-workspace-cleanup; after exception #{e.message}"

          retry if tries < max_tries

          raise e
        end
        true
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def possible?
        # only items can be OCR'd
        return false unless cocina_object.dro?

        # only specific content types can be OCR'd
        return false unless allowed_object_types.include? cocina_object.type

        # check to be sure there are actually files to be OCRed
        return false unless filenames_to_ocr.any?

        # Note that we check for the "correctedForAccessibility" attribute in cocina structural in the
        # `CocinaUpdater` class and skip adding those generated files as needed.

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

      # e.g. /abbyy/INPUT/ab123cd4567
      def cleanup_input_folder
        return unless Dir.exist?(abbyy_input_path)

        files = Dir.glob("#{abbyy_input_path}/*")
        logger.info "Removing ABBYY input directory: #{abbyy_input_path}.  Empty: #{Dir.empty?(abbyy_input_path)}. Num files/folders: #{files.count}: #{files.join(', ')}"
        delete_folder(abbyy_input_path)
      end

      # e.g. /abbyy/OUTPUT/ab123cd4567
      def cleanup_output_folder
        return unless Dir.exist?(abbyy_output_path)

        files = Dir.glob("#{abbyy_output_path}/*")
        logger.info "Removing ABBYY output directory: #{abbyy_output_path}.  Empty: #{Dir.empty?(abbyy_output_path)}. Num files/folders: #{files.count}: #{files.join(', ')}"
        delete_folder(abbyy_output_path)
      end

      # e.g. /abbyy/INPUT/ab123cd4567.xml
      def cleanup_xml_ticket
        xml_ticket_file = Abbyy::Ticket.new(filepaths: [], druid: cocina_object.externalIdentifier).file_path

        return unless File.exist?(xml_ticket_file)

        logger.info "Removing XML Ticket File: #{xml_ticket_file}"
        FileUtils.rm_r(xml_ticket_file)
      end

      # e.g. /abbyy/RESULTXML/ab123cd4567.xml.result.xml
      def cleanup_abbyy_results
        result_path = Dor::TextExtraction::Abbyy::Results.find_latest(druid: bare_druid)

        # this could be nil if there is no latest result XML file for this druid
        return unless result_path && File.exist?(result_path)

        logger.info "Removing XML Result File: #{result_path}"
        FileUtils.rm_r(result_path)
      end

      # e.g. /abbyy/EXCEPTIONS/druid:ab123cd4567.xml.result.xml
      def cleanup_abbyy_exceptions
        abbyy_exceptions = Dir.glob("#{Settings.sdr.abbyy.local_exception_path}/*#{bare_druid}*.xml")
        abbyy_exceptions.each do |abbyy_exception_file|
          logger.info "Removing XML Exception File: #{abbyy_exception_file}"
          FileUtils.rm_r(abbyy_exception_file)
        end
      end

      # iterate through cocina structural contains and return all File objects for files that need to be OCRed
      def ocr_files
        [].tap do |files|
          cocina_object.structural.contains.each do |fileset|
            next unless fileset.type.include?(matchtype)

            files << ocr_file(fileset)
          end
        end.compact
      end

      # filter down fileset files to those in preservation and are allowed mimetypes
      # if there are more than one allowed mimetype, grab the preferred type
      def ocr_file(fileset)
        perservedfiles = fileset.structural.contains.select { |file| file.administrative.sdrPreserve && allowed_mimetypes.include?(file.hasMimeType) }
        return perservedfiles[0] if perservedfiles.one?

        perservedfiles = perservedfiles.sort_by { |pfile| allowed_mimetypes.index(pfile.hasMimeType) }
        perservedfiles[0]
      end

      # defines the mimetypes types for which files for which OCR can possibly be run
      # preferentially select files for OCR by ordering of mimetypes below
      def allowed_mimetypes
        %w[
          image/tiff
          image/jpeg
          image/jp2
          application/pdf
        ]
      end

      # maps the allowed object types to the resource type we will look for files in
      def resource_type_mapping
        {
          Cocina::Models::ObjectType.book => 'page',
          Cocina::Models::ObjectType.document => 'document',
          Cocina::Models::ObjectType.image => 'image'
        }
      end

      def matchtype
        resource_type_mapping[cocina_object.type]
      end

      def allowed_object_types
        resource_type_mapping.keys
      end

      # shell out to remove a folder and all its contents since FileUtils.rm_r sometimes fails even if the directory is empty
      def delete_folder(folder)
        `rm -rf #{folder}`
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
