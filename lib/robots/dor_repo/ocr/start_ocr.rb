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
            object_client.version.open(description: 'Start OCR workflow') unless object_client.version.status.open?
          else
            skip_workflow
          end
        end

        private

        # skip entire ocrWF workflow without opening version if OCR is not possible for this object
        def skip_workflow
          workflow_name = 'ocrWF'
          status = 'skipped'
          note = 'No files available or invalid object for OCR'
          workflow = workflow_service.workflow(pid: druid, workflow_name:)
          # get all of the incomplete steps, except for ourself (start-ocr), we will set that with the usual ReturnState
          # and set them to skipped in inverse order (last one gets skipped first to avoid any later steps running)
          incomplete_steps = workflow.incomplete_processes.map(&:name).reject { |step| step == 'start-ocr' }.reverse
          incomplete_steps.each { |process| workflow_service.update_status(druid:, workflow: workflow_name, process:, status:, note:) }
          LyberCore::ReturnState.new(status: status.to_sym, note:)
        end
      end
    end
  end
end
