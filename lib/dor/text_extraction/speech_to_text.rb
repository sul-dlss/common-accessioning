# frozen_string_literal: true

module Dor
  module TextExtraction
    # Determine if speech to text is required and possible for a given object
    class SpeechToText
      attr_reader :cocina_object, :workflow_context, :bare_druid

      def initialize(cocina_object:, workflow_context: {})
        @cocina_object = cocina_object
        @workflow_context = workflow_context
        @bare_druid = cocina_object.externalIdentifier.delete_prefix('druid:')
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

      # return the s3 location for a given filename
      def s3_location(filename)
        File.join(job_id, filename)
      end

      # return the job_id for the stt job, defined as the druid-version of the object
      def job_id
        "#{bare_druid}-v#{cocina_object.version}"
      end

      private

      # iterate through cocina structural contains and return all File objects for files that need to be stt'd
      def stt_files
        [].tap do |files|
          cocina_object.structural.contains.each do |fileset|
            next unless allowed_resource_types.include? fileset.type

            files << stt_files_in_fileset(fileset)
          end
        end.flatten.compact
      end

      # filter down fileset files to those in preservation, that are shelved and are of an allowed mimetypes
      # return all of them
      def stt_files_in_fileset(fileset)
        fileset.structural.contains.select { |file| file.administrative.sdrPreserve && file.administrative.shelve && allowed_mimetypes.include?(file.hasMimeType) }
      end

      # defines the mimetypes types for which speech to text files can possibly be run
      def allowed_mimetypes
        %w[
          audio/mp4
          video/mp4
        ]
      end

      # the allowed structural metadata resources types that can contain files that can be stt'd
      def allowed_resource_types
        ['https://cocina.sul.stanford.edu/models/resources/audio', 'https://cocina.sul.stanford.edu/models/resources/video']
      end

      # the allowed objects that can have speech to text run on them
      def allowed_object_types
        [Cocina::Models::ObjectType.media]
      end
    end
  end
end
