# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # End the OCR process by closing the object version
      class EndOcr < LyberCore::Robot
        def initialize
          super('ocrWF', 'end-ocr')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          # close version
          true
        end
      end
    end
  end
end
