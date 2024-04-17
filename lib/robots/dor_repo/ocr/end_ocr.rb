# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # End the OCR process by closing the object version
      class EndOcr < LyberCore::Robot
        def initialize
          super('ocrWF', 'end-ocr')
        end

        def perform_work
          object_client.version.close
          true
        end
      end
    end
  end
end
