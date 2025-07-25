# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      class EndAccession < LyberCore::Robot
        def initialize
          super('accessionWF', 'end-accession')
        end

        def perform_work
          # Is there a specialized dissemination workflow?  (used by web archive workflow)
          next_dissemination_wf = special_dissemination_wf
          object_client.workflow(next_dissemination_wf).create(version: current_version, lane_id:) if next_dissemination_wf.present?

          start_captioning
        end

        private

        def current_version
          @current_version ||= object_client.version.current
        end

        # we will pass on any workflow context to the next version when starting OCR or speechToText
        # so that user selections like language will be available to the OCR/speechToText workflows,
        # but we will remove the context values that actually starts OCR/speechToText when doing this,
        # or else we will end up in an infinite loop, where the workflow gets triggered over and over again
        def workflow_context_for_next_version
          workflow.context.except('runOCR', 'runSpeechToText')
        end

        # check to see if we need to run OCR or speech-to-text or start workflow if needed
        # they are currently mutually exclusive, you cannot run both OCR and speech-to-text on the same object at the same time
        def start_captioning
          ocr = Dor::TextExtraction::Ocr.new(cocina_object:, workflow_context: workflow.context)
          stt = Dor::TextExtraction::SpeechToText.new(cocina_object:, workflow_context: workflow.context)

          # NOTE: since the first step of ocrWF or speechToTextWF opens a new version, we want this new WF to be associated
          #       with the next object version (the current version is about to be closed)
          next_version = (current_version.to_i + 1)

          if ocr.required?
            # user asked for OCR but the object is not OCRable
            raise 'Object cannot be OCRd' unless ocr.possible?

            object_client.workflow('ocrWF').create(version: next_version, lane_id:, context: workflow_context_for_next_version)
          elsif stt.required?
            # user asked for SpeechToText but the object is not speech-to-textable
            raise 'Object cannot have speech-to-text applied' unless stt.possible?

            object_client.workflow('speechToTextWF').create(version: next_version, lane_id:, context: workflow_context_for_next_version)
          end
        end

        # This returns any optional dissemination workflow such as wasDisseminationWF
        def special_dissemination_wf
          apo_id = cocina_object.administrative.hasAdminPolicy
          raise "#{cocina_object.externalIdentifier} doesn't have a valid apo" if apo_id.nil?

          apo = Dor::Services::Client.object(apo_id).find

          wf = apo.administrative.disseminationWorkflow
          wf unless wf == 'disseminationWF' # disseminationWF is gone so never start it - it's work is now done in reset-workspace
        end
      end
    end
  end
end
