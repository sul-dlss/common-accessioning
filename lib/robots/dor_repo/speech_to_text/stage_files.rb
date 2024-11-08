# frozen_string_literal: true

module Robots
  module DorRepo
    module SpeechToText
      # Copy STT files from remote workspace to local workspace
      class StageFiles < Dor::TextExtraction::Robot
        def initialize
          super('speechToTextWF', 'stage-files')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        # copy files from S3 workspace to local workspace
        def perform_work
          workspace_dir = object_client.workspace.create(content: true, metadata: true)
          workspace_content_folder = File.join(workspace_dir, 'content')
          raise 'No speech to text output files found' unless output_files.any?

          output_files.each do |s3_key|
            local_file_path = File.join(workspace_content_folder, File.basename(s3_key))
            download_file_from_s3(s3_key, local_file_path)
          end

          true
        end

        private

        # download a single file from the s3 workspace to the local workspace
        def download_file_from_s3(s3_key, local_file_path)
          File.open(local_file_path, 'wb') do |file|
            aws_provider.client.get_object(bucket: aws_provider.bucket_name, key: s3_key) do |chunk|
              file.write(chunk)
            end
          end
          logger.info("Downloaded #{s3_key} to #{local_file_path}")
        end

        # array of media files in the s3 output bucket folder for this job
        # only includes .txt and .vtt files
        def output_files
          @output_files ||= aws_provider.client.list_objects(bucket: aws_provider.bucket_name, prefix: s3_output_folder).contents.map(&:key).select { |filename| filename.end_with?('.txt', '.vtt') }
        end

        # the s3 output folder for this job
        def s3_output_folder
          Dor::TextExtraction::SpeechToText.new(cocina_object:).output_location
        end
      end
    end
  end
end
