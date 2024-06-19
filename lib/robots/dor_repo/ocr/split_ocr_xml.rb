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
          base_output_path = Dor::TextExtraction::Ocr.new(cocina_object:).abbyy_output_path
          alto_path = File.join(base_output_path, "#{bare_druid}.xml")
          return LyberCore::ReturnState.new(status: :skipped, note: 'No full object XML file') unless File.exist?(alto_path)

          Dor::TextExtraction::Abbyy::SplitAlto.new(alto_path:).write_files
        end
      end
    end
  end
end
