# frozen_string_literal: true

module Robots
  module DorRepo
    module SpeechToText
      # Start the speech to text process by opening the object version
      class StartStt < LyberCore::Robot
        def initialize
          super('speechToTextWF', 'start-stt')
        end

        def perform_work
          if Dor::TextExtraction::SpeechToText.new(cocina_object:).possible?
            Dor::TextExtraction::VersionUpdater.open(druid:, description: 'Start SpeechToText workflow', object_client:)
          else
            # skip all steps in the WF with note
            note = 'No files available or invalid object for Speech To Text'
            workflow_service.skip_all(druid:, workflow: 'speechToTextWF', note:)
            LyberCore::ReturnState.new(status: 'skipped', note:)
          end
        end
      end
    end
  end
end
