# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # This takes link for the object in the /dor/workspace directory and renames it so it has a version number.
      # It also cleans up the workspace directory.
      # (i.e. /dor/assembly/xw/754/sd/7436/xw754sd7436/ -> /dor/assembly/xw/754/sd/7436/xw754sd7436_v2/)
      class ResetWorkspace < LyberCore::Robot
        def initialize
          super('accessionWF', 'reset-workspace')
        end

        def perform_work
          # Reset workspace is performed async by dor-services-app.
          object_client.workspace.reset(workflow: 'accessionWF', lane_id:)

          # dor-services-app will update the workflow step, do don't do it here.
          LyberCore::ReturnState.new(status: :noop, note: 'Initiated reset API call.')
        end
      end
    end
  end
end
