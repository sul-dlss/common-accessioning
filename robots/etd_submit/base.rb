# frozen_string_literal: true

module Robots
  module DorRepo
    module EtdSubmit
      class Base
        include LyberCore::Robot

        def workflow_service
          Dor::Config.workflow.client
        end
      end
    end
  end
end
