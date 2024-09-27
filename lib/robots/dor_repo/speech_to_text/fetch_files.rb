# frozen_string_literal: true

module Robots
  module DorRepo
    module SpeechToText
      # Fetch files in need of Speech to Text from Preservation and send to S3
      class FetchFiles < Dor::TextExtraction::Robot
        def initialize
          super('speechToTextWF', 'fetch-files')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          sttable_filenames.each do |filename|
            raise "Unable to fetch #{filename} for #{druid}" unless file_fetcher.write_file_with_retries(filename:, location: aws_provider.bucket.object(File.join(job_id, filename)), max_tries: 3)
          end
        end

        private

        def sttable_filenames
          Dor::TextExtraction::SpeechToText.new(cocina_object:).filenames_to_stt
        end

        # this will be the base of the S3 key for the files sent (to namespace them in the bucket)
        # it is the same as the job_id when we send the SQS message
        def job_id
          @job_id ||= Dor::TextExtraction::SpeechToText.new(cocina_object:).job_id
        end

        def file_fetcher
          @file_fetcher ||= Dor::TextExtraction::FileFetcher.new(druid:, logger:)
        end
      end
    end
  end
end
