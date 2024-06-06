# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # Update the cocina structural metadata with the OCR files
      class UpdateCocina < LyberCore::Robot
        def initialize
          super('ocrWF', 'update-cocina')
        end

        def perform_work
          Dor::TextExtraction::CocinaUpdater.update(dro: cocina_object)
          object_client.update(params: cocina_object)

          cocina_object
        end
      end
    end
  end
end
