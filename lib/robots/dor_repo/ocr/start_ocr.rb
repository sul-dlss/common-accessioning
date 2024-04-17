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
          return LyberCore::ReturnState.new(status: :noop, note: 'Object is already open.') if object_client.version.status.open? # object is currently open

          object_client.version.open
          true
        end
      end
    end
  end
end
