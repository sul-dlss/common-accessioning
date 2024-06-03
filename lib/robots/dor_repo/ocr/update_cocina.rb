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
          Dor::TextExtraction::CocinaUpdater.update(dro: cocina_object, workspace_dir:)
          object_client.update(params: cocina_object)

          cocina_object
        end

        def workspace_dir
          DruidTools::Druid.new(druid, Settings.sdr.local_workspace_root).path
        end
      end
    end
  end
end
