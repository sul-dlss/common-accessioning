# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # This takes link for the object in the /dor/workspace directory and renames it so it has a version number.
      # (i.e. /dor/assembly/xw/754/sd/7436/xw754sd7436/ -> /dor/assembly/xw/754/sd/7436/xw754sd7436_v2/)
      class ResetWorkspace < LyberCore::Robot
        def initialize
          super('accessionWF', 'reset-workspace')
        end

        def perform_work
          object_client.workspace.reset
        end
      end
    end
  end
end
