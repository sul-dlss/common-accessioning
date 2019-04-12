# frozen_string_literal: true

module EtdSubmit
  module RobotCronBase
    attr_reader :repo, :workflow_name, :step_name, :prerequisites

    def start
      lanes = Dor::Config.workflow.client.get_lane_ids(*qualified_workflow_name.split(/:/))

      lanes.each do |lane|
        results = Dor::Config.workflow.client.get_objects_for_workstep(
          prerequisites,
          qualified_workflow_name,
          lane
        )

        results.each do |druid|
          work(druid)
        end
      end
    end

    def qualified_workflow_name
      @qualified_workflow_name ||= "#{repo}:#{workflow_name}:#{step_name}"
    end
  end
end
