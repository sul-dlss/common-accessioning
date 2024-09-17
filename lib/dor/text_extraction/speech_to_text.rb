# frozen_string_literal: true

module Dor
  module TextExtraction
    # Determine if speech to text is required and possible for a given object
    class SpeechToText
      attr_reader :cocina_object, :workflow_context, :bare_druid, :logger

      def initialize(cocina_object:, workflow_context: {}, logger: nil)
        @cocina_object = cocina_object
        @workflow_context = workflow_context
        @bare_druid = cocina_object.externalIdentifier.delete_prefix('druid:')
        @logger = logger || Logger.new($stdout)
      end

      def possible?
        # only items can have speech to text
        return false unless cocina_object.dro?

        # only specific content types can be speech to text'd
        return false unless allowed_object_types.include? cocina_object.type

        # check to be sure there are actually files to be speech to text'd
        return false unless filenames_to_stt.any?

        # TODO: check for any files that have "manuallyCorrected" in cocina structural (then skip)

        true
      end

      def required?
        # checks if user has indicated that speech to text should be run (sent as workflow_context)
        workflow_context['runSpeechToText'] || false
      end

      # return a list of filenames that should be stt'd
      # iterate over all files in cocina_object.structural.contains, looking at mimetypes
      # return a list of filenames that are correct mimetype
      def filenames_to_stt
        stt_files.map(&:filename)
      end

      private

      # iterate through cocina structural contains and return all File objects for files that need to be stt'd
      def stt_files
        [].tap do |files|
          cocina_object.structural.contains.each do |fileset|
            next unless fileset.type.include?(matchtype)

            files << stt_file(fileset)
          end
        end.compact
      end

      # filter down fileset files to those in preservation and are allowedmimetypes
      # if there are more than one allowed mimetype, grab the preferred type
      def stt_file(fileset)
        perservedfiles = fileset.structural.contains.select { |file| file.administrative.sdrPreserve && allowed_mimetypes.include?(file.hasMimeType) }
        return perservedfiles[0] if perservedfiles.one?

        perservedfiles = perservedfiles.sort_by { |pfile| allowed_mimetypes.index(pfile.hasMimeType) }
        perservedfiles[0]
      end

      # defines the mimetypes types for which speech to text files can possibly be run
      # preferentially select files for speech to text by ordering of mimetypes below
      # TODO: refine list of allowed mimetypes for speech to text
      # see https://github.com/sul-dlss/common-accessioning/issues/1346
      def allowed_mimetypes
        %w[
          audio/x-wav
          audio/mp4
          video/mp4
          video/mpeg
          video/quicktime
        ]
      end

      # maps the allowed object types to the resource type we will look for files in
      def resource_type_mapping
        {
          Cocina::Models::ObjectType.media => 'file'
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
