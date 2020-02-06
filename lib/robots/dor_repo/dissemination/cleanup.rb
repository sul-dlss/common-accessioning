# frozen_string_literal: true

module Robots
  module DorRepo
    module Dissemination
      class Cleanup < Robots::DorRepo::Base
        def initialize
          super('disseminationWF', 'cleanup')
        end

        def perform(druid)
          Dor::Services::Client.object(druid).workspace.cleanup
        end
      end
    end
  end
end
