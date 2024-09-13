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
          # TODO: copy files from preservation to STT workspace here
          # see similiar code in lib/robots/dor_repo/ocr/fetch_files.rb and refactor as needed to avoid duplication
          true
        end
      end
    end
  end
end
