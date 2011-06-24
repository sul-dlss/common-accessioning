# Publishes the objects metadata to the Digital Stacks' document cache
# Make sure ssl certs have been set up between machines

module Accession
  
  class Publish < LyberCore::Robots::Robot
    
    def initialize(opts = {})
      super('accessionWF', 'publish', opts)
    end

    def process_item(work_item)
      obj = Dor::Item.load_instance(work_item.druid)
      obj.publish_metadata
    end 
  end
end