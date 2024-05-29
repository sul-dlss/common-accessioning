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
          raise 'Object is already open' if object_client.version.status.open?
          raise 'No files available or invalid object for OCR' unless Dor::TextExtraction::Ocr.new(cocina_object:).possible?

          object_client.version.open(description: 'Start OCR workflow')
        end
      end
    end
  end
end
