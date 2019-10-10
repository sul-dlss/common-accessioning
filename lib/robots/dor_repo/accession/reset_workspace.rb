# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      class ResetWorkspace < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'reset-workspace')
        end

        def perform(druid)
          client = Dor::Services::Client.object(druid)
          client.workspace.reset
        end
      end
    end
  end
end
