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

        # Note that we check for the "correctedForAccessibility" attribute in cocina structural in the
        # `CocinaUpdater` class and skip adding those generated files as needed.

        true
      end

      def required?
        # checks if user has indicated that speech to text should be run (sent as workflow_context)
        workflow_context['runSpeechToText'] || false
      end

      # remove any files in S3 workspace that are no longer needed
      def cleanup
        cleanup_s3_folder
        true
      end

      # remove all files in the s3 input folder, the output folder is a subfolder, so gets cleaned up too
      def cleanup_s3_folder
        # Iterate over the list of filenames to be deleted (which is based on the job_id prefix for this druid)
        # use a trailing / on the job_id to avoid the cornercase of of version 1 and version 10 having the same prefix
        s3_objects = aws_provider.client.list_objects(bucket: aws_provider.bucket_name, prefix: "#{job_id}/")
        s3_objects.contents.each do |object|
          aws_provider.client.delete_object(bucket: aws_provider.bucket_name, key: object.key)
        end.size
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

      # return the s3 location for the output files generated by the speech to text service
      def output_location
        "#{job_id}/output"
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

      # filter down fileset files that could possibly be speech to texted to those that are in preservation
      # and shelved and are of an allowed mimetypes and return all of them
      def stt_files_in_fileset(fileset)
        files = fileset.structural.contains.select { |file| file.administrative.sdrPreserve && file.administrative.shelve && allowed_mimetypes.include?(file.hasMimeType) }
        files.reject { |file| existing_stt_file_corrected_for_accessibility?(fileset, file.filename) }
      end

      # look in resource structural metadata to find a matching speech to text file that has been corrected for accessibility
      # e.g. if the original file is "page1.tif", look for a "page1.txt" in the same resource that is
      # marked as "correctedForAccessibility" in it's cocina attribute, and then return true or false
      # this allows us to skip this captioning this file, since there is no point in doing it (since we wouldn't
      # want to overwrite the existing manually corrected caption file)
      def existing_stt_file_corrected_for_accessibility?(fileset, filename)
        basename = File.basename(filename, File.extname(filename)) # filename without extension
        corresponding_stt_file = "#{basename}.vtt"
        fileset.structural.contains.find do |file|
          file.filename == corresponding_stt_file && file.correctedForAccessibility
        end
      end

      # defines the mimetypes types for which speech to text files can possibly be run
      def allowed_mimetypes
        %w[
          audio/x-m4a
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

      def aws_provider
        @aws_provider ||= Dor::TextExtraction::AwsProvider.new(region: Settings.aws.region, access_key_id: Settings.aws.access_key_id, secret_access_key: Settings.aws.secret_access_key)
      end
    end
  end
end
