# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # Cleanup empty input and output folders in ABBYY OCR workspace
      class OcrWorkspaceCleanup < LyberCore::Robot
        def initialize
          super('ocrWF', 'ocr-workspace-cleanup')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          Dor::TextExtraction::Ocr.new(cocina_object:, logger:).cleanup
        end
      end
    end
  end
end
