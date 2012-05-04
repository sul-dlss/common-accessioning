# Runs all registered dor-services migrations on the object

module Accession
  
  class RemediateObject < LyberCore::Robots::Robot
    
    def initialize(opts = {})
      super('accessionWF', 'remediate-object', opts)
    end

    def process_item(work_item)
      obj = Dor::Item.load_instance(work_item.druid)
      obj.upgrade!
    end 
  end
end
