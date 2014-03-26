
module Accession

  class EndAccession < LyberCore::Robots::Robot

    def initialize
      super('dor', 'accessionWF', 'end-accession')
    end

    def perform(druid)
      obj = Dor::Item.find(druid)
      obj.clear_diff_cache
      Dor::WorkflowService.update_workflow_status('dor', druid, 'disseminationWF', 'cleanup', 'waiting')
    end
  end
end
