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
            raise "Unable to fetch #{filename} for #{druid}" unless file_fetcher.write_file_with_retries(filename:, location: aws_provider.bucket.object(File.join(bare_druid, filename)), max_tries: 3)
          end
        end

        private

        def sttable_filenames
          Dor::TextExtraction::SpeechToText.new(cocina_object:, workflow_context: workflow.context).filenames_to_stt
        end

        def file_fetcher
          @file_fetcher ||= Dor::TextExtraction::FileFetcher.new(druid:, logger:)
        end
      end
    end
  end
end
