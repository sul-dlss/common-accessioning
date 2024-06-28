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
          if Dor::TextExtraction::Ocr.new(cocina_object:).possible?
            open_object unless object_client.version.status.open?
          else
            # skip all steps in the WF with note
            note = 'No files available or invalid object for OCR'
            workflow_service.skip_all(druid:, workflow: 'ocrWF', note:)
            LyberCore::ReturnState.new(status: 'skipped', note:)
          end
        end

        private

        def open_object
          tries = 0
          begin
            object_client.version.open(description: 'Start OCR workflow')
          rescue Dor::Services::Client::UnexpectedResponse => e
            tries += 1
            sleep(2**tries)

            raise e unless tries < 3

            Honeybadger.notify('[NOTE] Problem opening object version at start of ocrWF', context: { druid:, tries:, error: e })
            retry
          end
        end
      end
    end
  end
end
