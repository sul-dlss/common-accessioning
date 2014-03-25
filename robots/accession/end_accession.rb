
module Accession

  class EndAccession < LyberCore::Robots::Robot

    def initialize
      super('dor', 'accessionWF', 'end-accession')
    end

    def process_item
      obj = Dor::Item.find(@druid)
      obj.clear_diff_cache
      Dor::WorkflowService.update_workflow_status('dor', work_item.druid, 'disseminationWF', 'cleanup', 'waiting')
    end
  end
end
