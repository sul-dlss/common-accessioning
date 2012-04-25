# Clears the way for the standalone publishing robot to publish 
# the object's metadata to the Digital Stacks' document cache

module Accession
  
  class Publish < LyberCore::Robots::Robot
    
    def initialize(opts = {})
      super('accessionWF', 'publish', opts)
    end

    def process_item(work_item)
      start_time = Time.new
      obj = Dor::Item.load_instance(work_item.druid)
      obj.publish_metadata
      elapsed = Time.new - start_time
      Dor::WorkflowService.update_workflow_status('dor',work_item.druid,'disseminationWF','publish','completed',elapsed,'published')
    end 
  end
end