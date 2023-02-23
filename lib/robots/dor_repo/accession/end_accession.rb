# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      class EndAccession < LyberCore::Robot
        def initialize
          super('accessionWF', 'end-accession')
        end

        def perform_work
          current_version = object_client.version.current

          # Search for the specialized workflow
          next_dissemination_wf = special_dissemination_wf
          workflow_service.create_workflow_by_name(druid, next_dissemination_wf, version: current_version, lane_id: lane_id) if next_dissemination_wf.present?

          # Call cleanup
          # Note that this used to be handled by the disseminationWF, which is no longer used.
          object_client.workspace.cleanup(workflow: 'accessionWF', lane_id: lane_id)
          LyberCore::ReturnState.new(status: :noop, note: 'Initiated cleanup API call.')
        end

        private

        # This returns any optional workflow such as wasDisseminationWF
        def special_dissemination_wf
          apo_id = cocina_object.administrative.hasAdminPolicy
          raise "#{cocina_object.externalIdentifier} doesn't have a valid apo" if apo_id.nil?

          apo = Dor::Services::Client.object(apo_id).find

          wf = apo.administrative.disseminationWorkflow
          return wf unless wf == 'disseminationWF'
        end
      end
    end
  end
end
