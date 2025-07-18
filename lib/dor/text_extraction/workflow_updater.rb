# frozen_string_literal: true

module Dor
  module TextExtraction
    # Update the status of workflow steps in SDR based on text extraction (OCR, speech-to-text) processing events
    class WorkflowUpdater
      OCR_WF_NAME = 'ocrWF'
      OCR_WF_CREATE_NAME = 'ocr-create'
      STT_WF_NAME = 'speechToTextWF'
      STT_WF_CREATE_NAME = 'stt-create'

      # Notify SDR that the OCR workflow step completed successfully
      def mark_ocr_create_completed(druid)
        workflow(druid:, workflow_name: OCR_WF_NAME, process: OCR_WF_CREATE_NAME).workflow_process.update(status: 'completed')
      end

      # Notify SDR that the OCR workflow step failed
      def mark_ocr_create_errored(druid, error_msg:)
        workflow(druid:, workflow_name: OCR_WF_NAME, process: OCR_WF_CREATE_NAME).workflow_process.update_error(error_msg:)
      end

      # Notify SDR that the speech-to-text workflow step completed successfully
      def mark_stt_create_completed(druid)
        workflow(druid:, workflow_name: STT_WF_NAME, process: STT_WF_CREATE_NAME).workflow_process.update(status: 'completed')
      end

      # Notify SDR that the speech-to-text workflow step failed
      def mark_stt_create_errored(druid, error_msg:)
        workflow(druid:, workflow_name: STT_WF_NAME, process: STT_WF_CREATE_NAME).workflow_process.update_error(error_msg:)
      end

      private

      def object_client(druid)
        Dor::Services::Client.object(druid)
      end

      def workflow(druid:, workflow_name:, process:)
        LyberCore::Workflow.new(object_client: object_client(druid), workflow_name:, process:)
      end
    end
  end
end
