# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class AccessioningInitiate < Robots::DorRepo::Assembly::Base
        def initialize(opts = {})
          super('dor', 'assemblyWF', 'accessioning-initiate', opts)
        end

        def perform(druid)
          @ai = item(druid)
          LyberCore::Log.info("Inititate accessioning for #{@ai.druid.id}")
          initialize_workspace if @ai.item?
          start_accession_workflow
          true
        end

        private

        def initialize_workspace
          Dor::Services::Client.object(@ai.druid.druid).workspace.create(source: @ai.path_to_object)
        end

        def start_accession_workflow
          Dor::Config.workflow.client.create_workflow_by_name(@ai.druid.druid, 'accessionWF')
        end
      end
    end
  end
end
