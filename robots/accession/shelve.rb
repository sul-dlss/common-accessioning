
module Accession
  
  class Shelve < LyberCore::Robots::Robot

    def initialize(opts = {})
      super('accessionWF', 'shelve', opts)
    end

    def process_item(work_item)
      obj = Dor::Item.load_instance(work_item.druid)
      obj.shelve
    end
    
  end

end


