# frozen_string_literal: true

require_relative './base'
require 'dor/services/client'

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
          initialize_workflow
          true
        end

        private

        def initialize_workspace
          Dor::Services::Client.object(@ai.druid.druid).workspace.create(source: @ai.path_to_object)
        end

        def initialize_workflow
          Dor::Services::Client.object(@ai.druid.druid).workflow.create(wf_name: 'accessionWF')
        end
      end
    end
  end
end
