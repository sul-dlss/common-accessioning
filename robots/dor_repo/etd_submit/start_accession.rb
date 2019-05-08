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
          Dor::Services::Client.object(druid).workflow.create(wf_name: workflow_name)
        end

        private

        def workflow_name
          'accessionWF'
        end
      end
    end
  end
end
