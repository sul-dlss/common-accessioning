# Clears the way for the standalone publishing robot to publish 
# the object's metadata to the Digital Stacks' document cache

module Accession
  
  class Release < LyberCore::Robots::Robot
    
    def initialize(opts = {})
      super('accessionWF', 'release', opts)
    end

    def process_item(work_item)
      start_time = Time.new
      obj = Dor::Item.load_instance(work_item.druid)
      obj.publish_metadata
      elapsed = Time.new - start_time
      Dor::WorkflowService.update_workflow_status('dor',work_item.druid,'postAccessionWF','publish','completed',elapsed,'published')
    end 
  end
end