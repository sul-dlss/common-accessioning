# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # Update the cocina structural metadata with the OCR files
      class UpdateCocina < LyberCore::Robot
        def initialize
          super('ocrWF', 'update-cocina')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          # update cocina structural metadata with OCR files
        end
      end
    end
  end
end
