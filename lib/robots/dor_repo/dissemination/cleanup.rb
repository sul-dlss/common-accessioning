# frozen_string_literal: true

module Robots
  module DorRepo
    module Dissemination
      # This step has been merged into the end accession robot. It should no longer be used.
      class Cleanup < LyberCore::Robot
        def initialize
          super('disseminationWF', 'cleanup')
        end

        def perform_work
          Honeybadger.notify('[WARNING] DisseminationWF:cleanup robot is deprecated and should not be used.', context: { druid: })
          # Oct 3 2024: just warn, do not actually do the work.  If we never see these warnings, we can get rid of this robot.
          # object_client.workspace.cleanup(workflow: 'disseminationWF', lane_id:)
          LyberCore::ReturnState.new(status: :noop, note: 'Initiated cleanup API call.')
        end
      end
    end
  end
end
