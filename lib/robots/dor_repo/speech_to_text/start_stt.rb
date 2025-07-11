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
            return if object_client.version.status.open?

            object_client.version.open(description: 'Start SpeechToText workflow')
          else
            # skip all steps in the WF with note
            note = 'No files available or invalid object for Speech To Text'
            object_workflow.skip_all(note:)
            LyberCore::ReturnState.new(status: 'skipped', note:)
          end
        end
      end
    end
  end
end
