# frozen_string_literal: true

module EtdSubmit
  module RobotCronBase
    attr_reader :prerequisites

    def start
      lanes = workflow_service.lane_ids(*qualified_workflow_name.split(/:/))

      lanes.each do |lane|
        results = workflow_service.objects_for_workstep(
          prerequisites,
          qualified_workflow_name,
          lane
        )

        results.each do |druid|
          Honeybadger.context(druid: druid)
          work(druid)
        end
      end
    end

    def qualified_workflow_name
      @qualified_workflow_name ||= "dor:#{workflow_name}:#{process}"
    end
  end
end
