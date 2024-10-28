# frozen_string_literal: true

module Robots
  module DorRepo
    module SpeechToText
      # Cleanup any speech to text workspace files
      class SttWorkspaceCleanup < LyberCore::Robot
        def initialize
          super('speechToTextWF', 'stt-workspace-cleanup')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          Dor::TextExtraction::SpeechToText.new(cocina_object:).cleanup
        end
      end
    end
  end
end
