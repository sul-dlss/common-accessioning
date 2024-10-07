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
          object_client.workspace.cleanup(workflow: 'disseminationWF', lane_id:)
          # Oct 3 2024:  Warn. If we never see these warnings, we can get rid of this robot completely.
          Honeybadger.notify('[WARNING] DisseminationWF:cleanup robot is deprecated and should not be used.', context: { druid: })
          LyberCore::ReturnState.new(status: :noop, note: 'Initiated cleanup API call.')
        end
      end
    end
  end
end
