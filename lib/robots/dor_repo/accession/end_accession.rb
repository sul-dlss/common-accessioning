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
          workflow_service.create_workflow_by_name(druid, next_dissemination_wf, version: current_version, lane_id:) if next_dissemination_wf.present?

          start_captioning
        end

        private

        def current_version
          @current_version ||= object_client.version.current
        end

        # check to see if we need to run OCR or speech-to-text or start workflow if needed
        # they are currently mutually exclusive, you cannot run both OCR and speech-to-text on the same object at the same time
        def start_captioning
          # NOTE: the "workflow" object that is providing the context is a LyberCore::Workflow class
          # It is provided by the LyberCore::Robot superclass via lyber-core gem
          # see https://github.com/sul-dlss/lyber-core/blob/main/lib/lyber_core/robot.rb and https://github.com/sul-dlss/lyber-core/blob/main/lib/lyber_core/workflow.rb
          ocr = Dor::TextExtraction::Ocr.new(cocina_object:, workflow_context: workflow.context)
          stt = Dor::TextExtraction::SpeechToText.new(cocina_object:, workflow_context: workflow.context)

          if ocr.required?
            # user asked for OCR but the object is not OCRable
            raise 'Object cannot be OCRd' unless ocr.possible?

            start_caption_workflow('ocrWF')
          elsif stt.required?
            # user asked for SpeechToText but the object is not speech-to-textable
            raise 'Object cannot have speech-to-text applied' unless stt.possible?

            start_caption_workflow('speechToTextWF')
          end
        end

        def start_caption_workflow(workflow_name)
          # NOTES:
          # 1. since the first step of ocrWF or speechToTextWF opens a new version, we want this new WF to be associated
          #       with the next object version (the current version is about to be closed)
          # 2. we need to pass in any existing workflow version context from the previous version because it can contain
          #       user provided values (such as language selection)
          workflow_service.create_workflow_by_name(druid, workflow_name, version: (current_version.to_i + 1), lane_id:, context: workflow.context)
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
