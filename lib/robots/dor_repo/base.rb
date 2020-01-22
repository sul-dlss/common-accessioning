# frozen_string_literal: true

module Robots
  module DorRepo
    class Base
      include LyberCore::Robot

      def workflow_service
        Dor::Config.workflow.client
      end

      def lane_id(druid)
        workflow_service.process(pid: druid, workflow_name: @workflow_name, process: @step_name).lane_id
      end
    end
  end
end
