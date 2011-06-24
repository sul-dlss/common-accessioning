
module Accession
  
  class Shelve < LyberCore::Robots::Robot

    def initialize(opts = {})
      super('accessionWF', 'shelve', opts)
    end

    def process_item(work_item)

    end
    
  end

end


