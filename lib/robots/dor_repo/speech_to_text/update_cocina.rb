# frozen_string_literal: true

module Robots
  module DorRepo
    module SpeechToText
      # Update the cocina structural metadata with the OCR files
      class UpdateCocina < LyberCore::Robot
        def initialize
          super('speechToTextWF', 'update-cocina')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          Dor::TextExtraction::SpeechToTextCocinaUpdater.update(dro: cocina_object, logger:)
          object_client.update(params: cocina_object)

          cocina_object
        end
      end
    end
  end
end
