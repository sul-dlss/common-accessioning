# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      # This creates a symlink in /dor/workspace to the files in /dor/assembly
      # (i.e. /dor//workspace/xw/754/sd/7436/xw754sd7436 -> /dor/assembly/xw/754/sd/7436/xw754sd7436)
      # and then triggers the accessioningWF
      class AccessioningInitiate < Robots::DorRepo::Assembly::Base
        def initialize
          super('assemblyWF', 'accessioning-initiate')
        end

        def perform_work
          logger.info("Initiate accessioning for #{druid}")
          initialize_workspace if assembly_item.item?
          start_accession_workflow
          true
        end

        private

        def initialize_workspace
          object_client.workspace.create(source: assembly_item.path_finder.path_to_object)
        end

        def start_accession_workflow
          current_version = object_client.version.current
          workflow_service.create_workflow_by_name(druid, 'accessionWF', version: current_version, lane_id: lane_id)
        end
      end
    end
  end
end
