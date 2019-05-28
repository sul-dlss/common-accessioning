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
          Dor::Config.workflow.client.create_workflow_by_name(druid, 'accessionWF')
        end
      end
    end
  end
end
