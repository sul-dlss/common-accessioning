# Publishes the objects metadata to the Digital Stacks' document cache
# Make sure ssl certs have been set up between machines

module Accession
  
  class Publish < LyberCore::Robots::Robot
    
    def initialize(opts = {})
      super('accessionWF', 'shelve', opts)
    end

    def process_item(work_item)
      obj = Dor::Base.load_instance(work_item.druid)
      obj.publish_metadata
    end 
  end
end