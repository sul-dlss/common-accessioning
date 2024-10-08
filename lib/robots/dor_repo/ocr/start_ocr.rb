# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # Start the OCR process by opening the object version
      class StartOcr < LyberCore::Robot
        def initialize
          super('ocrWF', 'start-ocr')
        end

        def perform_work
          if Dor::TextExtraction::Ocr.new(cocina_object:).possible?
            return if object_client.version.status.open?

            object_client.version.open(description: 'Start OCR workflow')
          else
            # skip all steps in the WF with note
            note = 'No files available or invalid object for OCR'
            workflow_service.skip_all(druid:, workflow: 'ocrWF', note:)
            LyberCore::ReturnState.new(status: 'skipped', note:)
          end
        end
      end
    end
  end
end
