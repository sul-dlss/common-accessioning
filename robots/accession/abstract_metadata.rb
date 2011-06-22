# Ensures the existence of a given datastream within
# a digital object, and loads it from the appropriate 
# source if necessary.

module Accession
  
  class AbstractMetadata < LyberCore::Robots::Robot
    @@process_name = nil
    @@datastream = nil
    
    def initialize
      super('accessionWF', @@process_name)
    end

    def process_item(work_item)
      obj = Dor::Item.find(work_item.druid)
      obj.build_datastream(@@datastream)
    end 
  end
end