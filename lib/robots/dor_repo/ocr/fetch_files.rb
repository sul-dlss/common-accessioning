# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # Fetch files in need of OCR from Preservation
      class FetchFiles < LyberCore::Robot
        def initialize
          super('ocrWF', 'fetch-files')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          ocrable_filenames.each do |filename|
            path = abbyy_path(filename)
            path.parent.mkpath unless path.parent.directory?
            raise "Unable to fetch #{filename} for #{druid}" unless file_fetcher.write_file_with_retries(filename:, path:, max_tries: 3)
          end
        end

        private

        def abbyy_path(filename)
          # NOTE: if files of type "file" were allowed here we would have to
          # deal with file hierarchy (subdirectories)
          Pathname.new(File.join(ocr.abbyy_input_path, filename))
        end

        def ocrable_filenames
          @ocrable_filenames ||= ocr.filenames_to_ocr
        end

        def ocr
          @ocr ||= Dor::TextExtraction::Ocr.new(cocina_object:, workflow_context: workflow.context)
        end

        def file_fetcher
          @file_fetcher ||= Dor::TextExtraction::FileFetcher.new(druid:, logger:)
        end
      end
    end
  end
end
