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
          api_client.object(druid).workflow.create(wf_name: workflow_name)
        end

        private

        def api_client
          @api_client ||= Dor::Services::Client.configure(url: Dor::Config.dor_services.url,
                                                          username: Dor::Config.dor_services.user,
                                                          password: Dor::Config.dor_services.pass)
        end

        def workflow_name
          'accessionWF'
        end
      end
    end
  end
end