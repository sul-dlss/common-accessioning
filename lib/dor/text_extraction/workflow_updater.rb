# frozen_string_literal: true

module Dor
  module TextExtraction
    # Update the status of workflow steps in SDR based on OCR processing events
    class WorkflowUpdater
      attr_reader :workflow, :step

      # Default is to update the 'ocr-create' step in the 'ocrWF' workflow
      def initialize(workflow: 'ocrWF', step: 'ocr-create', client: nil, logger: nil)
        @workflow = workflow
        @step = step
        @client = client || LyberCore::WorkflowClientFactory.build(logger:)
      end

      # Notify SDR that the OCR workflow step completed successfully
      def mark_ocr_completed(druid)
        @client.update_status(druid:, workflow:, process: step, status: 'completed')
      end

      # Notify SDR that the OCR workflow step failed
      def mark_ocr_errored(druid, error_message:)
        @client.update_status(druid:, workflow:, process: step, status: 'error', note: error_message)
      end
    end
  end
end
