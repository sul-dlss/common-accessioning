# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # Copy OCR files from ABBYY output folder to the workspace
      class StageFiles < LyberCore::Robot
        def initialize
          super('ocrWF', 'xml-ticket-create')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          # Copy OCR files from ABBYY output folder to the workspace
        end
      end
    end
  end
end
