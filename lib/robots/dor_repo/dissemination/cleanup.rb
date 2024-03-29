# frozen_string_literal: true

module Robots
  module DorRepo
    module Dissemination
      # NOTE: This step has been merged into the end accession robot. It should no longer be used, but is left in case
      # there are existing workflow steps that require it.
      class Cleanup < LyberCore::Robot
        def initialize
          super('disseminationWF', 'cleanup')
        end

        def perform_work
          object_client.workspace.cleanup(workflow: 'disseminationWF', lane_id:)
          LyberCore::ReturnState.new(status: :noop, note: 'Initiated cleanup API call.')
        end
      end
    end
  end
end
