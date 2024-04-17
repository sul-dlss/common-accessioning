# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # Call the OCR service to generate ocr
      class OcrCreate < LyberCore::Robot
        def initialize
          super('ocrWF', 'ocr-create')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          # do the ocr creation by calling out to ABBYY
          true
        end
      end
    end
  end
end
