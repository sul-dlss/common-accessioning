# frozen_string_literal: true

module Robots
  module DorRepo
    module Dissemination
      # NOTE: This step has been merged into the end accession robot. It should no longer be used, but is left in case
      # there are existing workflow steps that require it.
      class Cleanup < Robots::DorRepo::Base
        def initialize
          super('disseminationWF', 'cleanup')
        end

        def perform(druid)
          Dor::Services::Client.object(druid).workspace.cleanup(workflow: 'disseminationWF', lane_id: lane_id(druid))
          LyberCore::Robot::ReturnState.new(status: :noop, note: 'Initiated cleanup API call.')
        end
      end
    end
  end
end
