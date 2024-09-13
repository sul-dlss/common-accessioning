# frozen_string_literal: true

module Robots
  module DorRepo
    module SpeechToText
      # Copy STT files from remote workspace to local workspace
      class StageFiles < LyberCore::Robot
        def initialize
          super('speechToTextWF', 'stage-files')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          # TODO: copy files from STT workspace to local workspace
          # see similiar code in lib/robots/dor_repo/ocr/stage_files.rb and refactor as needed to avoid duplication
          true
        end
      end
    end
  end
end
