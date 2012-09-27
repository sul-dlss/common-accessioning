# Ensures the existence of a given datastream within
# a digital object, and loads it from the appropriate 
# source if necessary.

module Accession
  
  class AbstractMetadata < LyberCore::Robots::Robot
    def self.params
      { :process_name => nil, :datastream => nil }
    end
    
    def initialize(opts = {})
      super('accessionWF', self.class.params[:process_name], opts)
    end

    def process_item(work_item)
      obj = Dor::Item.find(work_item.druid)
      obj.build_datastream(self.class.params[:datastream], self.class.params[:force] ? true : false)
    end 
  end
end