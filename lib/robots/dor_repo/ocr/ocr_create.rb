# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # Call the OCR service to generate ocr
      class OcrCreate < LyberCore::Robot
        def initialize
          super('ocrWF', 'ocr-create')
        end

        # available from LyberCore::Robot: druid, bare_druid, object_workflow, object_client, cocina_object, logger
        def perform_work
          # Leave this step running until the OCR monitoring job marks it as complete
          LyberCore::ReturnState.new(status: :noop, note: 'Initiated ABBYY OCRing.')
        end
      end
    end
  end
end
