# frozen_string_literal: true

module Robots
  module DorRepo
    module SpeechToText
      # Fetch files in need of OCR from Preservation
      class FetchFiles < LyberCore::Robot
        def initialize
          super('speechToTextWF', 'fetch-files')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          sttable_filenames.each do |filename|
            raise "Unable to fetch #{filename} for #{druid}" unless file_fetcher.write_file_with_retries(filename: s3_pathname(filename), bucket: Settings.aws.base_s3_bucket, max_tries: 3)
          end
        end

        private

        def s3_pathname(filename)
          File.join(bare_druid, filename)
        end

        def sttable_filenames
          @sttable_filenames ||= speech_to_text.filenames_to_stt
        end

        def speech_to_text
          @speech_to_text ||= Dor::TextExtraction::SpeechToText.new(cocina_object:, workflow_context: workflow.context)
        end

        def file_fetcher
          @file_fetcher ||= Dor::TextExtraction::FileFetcher.new(druid:, logger:)
        end
      end
    end
  end
end
