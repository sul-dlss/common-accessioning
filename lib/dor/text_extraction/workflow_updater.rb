# frozen_string_literal: true

module Dor
  module TextExtraction
    # Update the status of workflow steps in SDR based on OCR processing events
    class WorkflowUpdater
      OCR_WF_NAME = 'ocrWF'
      OCR_WF_CREATE_NAME = 'ocr-create'

      # Default is to update the 'ocr-create' step in the 'ocrWF' workflow
      def initialize(client: nil, logger: nil)
        @client = client || LyberCore::WorkflowClientFactory.build(logger:)
      end

      # Notify SDR that the OCR workflow step completed successfully
      def mark_ocr_create_completed(druid)
        @client.update_status(druid:, workflow: OCR_WF_NAME, process: OCR_WF_CREATE_NAME, status: 'completed')
      end

      # Notify SDR that the OCR workflow step failed
      def mark_ocr_create_errored(druid, error_msg:)
        @client.update_error_status(druid:, workflow: OCR_WF_NAME, process: OCR_WF_CREATE_NAME, error_msg:)
      end
    end
  end
end
