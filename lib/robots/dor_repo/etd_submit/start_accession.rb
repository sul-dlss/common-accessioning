#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dor/services/client'

module Robots
  module DorRepo
    module EtdSubmit
      class StartAccession < Robots::DorRepo::EtdSubmit::Base
        def initialize(opts = {})
          super('dor', 'etdSubmitWF', 'start-accession', opts)
        end

        def perform(druid)
          object_client = Dor::Services::Client.object(druid)
          current_version = object_client.version.current
          Dor::Config.workflow.client.create_workflow_by_name(druid, 'accessionWF', version: current_version)
        end
      end
    end
  end
end
