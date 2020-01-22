# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      # This creates a symlink in /dor/workspace to the files in /dor/assembly
      # (i.e. /dor//workspace/xw/754/sd/7436/xw754sd7436 -> /dor/assembly/xw/754/sd/7436/xw754sd7436)
      # and then triggers the accessioningWF
      class AccessioningInitiate < Robots::DorRepo::Assembly::Base
        def initialize(opts = {})
          super('dor', 'assemblyWF', 'accessioning-initiate', opts)
        end

        def perform(druid)
          @ai = item(druid)
          LyberCore::Log.info("Inititate accessioning for #{@ai.druid.id}")
          initialize_workspace if @ai.item?
          start_accession_workflow(druid)
          true
        end

        private

        def initialize_workspace
          Dor::Services::Client.object(@ai.druid.druid).workspace.create(source: @ai.path_finder.path_to_object)
        end

        def start_accession_workflow(druid)
          object_client = Dor::Services::Client.object(@ai.druid.druid)
          current_version = object_client.version.current
          Dor::Config.workflow.client.create_workflow_by_name(@ai.druid.druid, 'accessionWF', version: current_version, lane_id: lane_id(druid))
        end
      end
    end
  end
end
