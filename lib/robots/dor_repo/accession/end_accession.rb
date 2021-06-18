# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      class EndAccession < Robots::DorRepo::Base
        def initialize
          super('accessionWF', 'end-accession')
        end

        def perform(druid)
          object_client = Dor::Services::Client.object(druid)
          current_version = object_client.version.current

          # Search for the specialized workflow
          next_dissemination_wf = special_dissemination_wf(object_client)
          workflow_service.create_workflow_by_name(druid, next_dissemination_wf, version: current_version, lane_id: lane_id(druid)) if next_dissemination_wf.present?

          # Call cleanup
          # Note that this used to be handled by the disseminationWF, which is no longer used.
          # This is an asynchronous result. It will set the end-accession workflow step to complete when it is done.
          object_client.workspace.cleanup
          LyberCore::Robot::ReturnState.new(status: :noop, note: 'Initiated end-accession API call.')
        end

        private

        # This returns any optional workflow such as wasDisseminationWF
        def special_dissemination_wf(object_client)
          druid_obj = object_client.find
          apo_id = druid_obj.administrative.hasAdminPolicy
          raise "#{druid_obj.externalIdentifier} doesn't have a valid apo" if apo_id.nil?

          apo = Dor::Services::Client.object(apo_id).find

          wf = apo.administrative.disseminationWorkflow
          return wf unless wf == 'disseminationWF'
        end
      end
    end
  end
end
