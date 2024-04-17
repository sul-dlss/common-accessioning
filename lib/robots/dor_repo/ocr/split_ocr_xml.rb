# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # Split the OCR XML into page level OCR XML
      class SplitOcrXml < LyberCore::Robot
        def initialize
          super('ocrWF', 'split-ocr-xml')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          # split single document OCR XML into page level OCR XML
          true
        end
      end
    end
  end
end
