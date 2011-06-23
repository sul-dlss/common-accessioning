# Ensures the existence of a given datastream within
# a digital object, and loads it from the appropriate 
# source if necessary.

module Accession
  
  class AbstractMetadata < LyberCore::Robots::Robot
    def self.params
      { :process_name => nil, :datastream => nil }
    end
    
    def initialize
      super('accessionWF', self.class.params[:process_name])
    end

    def process_item(work_item)
      obj = Dor::Item.load_instance(work_item.druid)
      obj.build_datastream(self.class.params[:datastream])
    end 
  end
end