# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      class EndAccession < LyberCore::Robot
        def initialize
          super('accessionWF', 'end-accession')
        end

        # rubocop:disable Metrics/AbcSize
        def perform_work
          current_version = object_client.version.current

          # Is there a specialized dissemination workflow?  (used by web archive workflow)
          next_dissemination_wf = special_dissemination_wf
          workflow_service.create_workflow_by_name(druid, next_dissemination_wf, version: current_version, lane_id:) if next_dissemination_wf.present?

          # Note that this used to be handled by the disseminationWF, which is no longer used.
          object_client.workspace.cleanup(workflow: 'accessionWF', lane_id:)

          # NOTE: the "workflow" object that is providing the context is a LyberCore::Workflow class
          # It is provided by the LyberCore::Robot superclass via lyber-core gem
          # see https://github.com/sul-dlss/lyber-core/blob/main/lib/lyber_core/robot.rb and https://github.com/sul-dlss/lyber-core/blob/main/lib/lyber_core/workflow.rb
          ocr = Dor::TextExtraction::Ocr.new(cocina_object:, workflow_context: workflow.context)

          if ocr.required?
            # user asked for OCR but the object is not OCRable
            raise 'Object cannot be OCRd' unless ocr.possible?

            # start OCR workflow
            workflow_service.create_workflow_by_name(druid, 'ocrWF', version: current_version, lane_id:)
          end

          # TODO: Start captionioning text extraction workflow if needed
          # workflow_service.create_workflow_by_name(druid, 'captioningWF', version: current_version, lane_id:) if Dor::TextExtraction::Captioning.new(cocina_object:, workflow_context: workflow.context).required?

          LyberCore::ReturnState.new(status: :noop, note: 'Initiated cleanup API call.')
        end
        # rubocop:enable Metrics/AbcSize

        private

        # This returns any optional dissemination workflow such as wasDisseminationWF
        def special_dissemination_wf
          apo_id = cocina_object.administrative.hasAdminPolicy
          raise "#{cocina_object.externalIdentifier} doesn't have a valid apo" if apo_id.nil?

          apo = Dor::Services::Client.object(apo_id).find

          wf = apo.administrative.disseminationWorkflow
          wf unless wf == 'disseminationWF'
        end
      end
    end
  end
end
