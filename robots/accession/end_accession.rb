
module Accession

  class EndAccession < LyberCore::Robots::Robot

    def initialize(opts={})
      super('accessionWF', 'end-accession', opts)
    end

    def process_item(work_item)
      obj = Dor::Item.find(work_item.druid)
      obj.clear_diff_cache
      Dor::WorkflowService.update_workflow_status('dor', work_item.druid, 'disseminationWF', 'cleanup', 'waiting')
    end
  end
end
