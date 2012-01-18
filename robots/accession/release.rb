# Clears the way for the standalone publishing robot to publish 
# the object's metadata to the Digital Stacks' document cache

module Accession
  
  class Release < LyberCore::Robots::Robot
    
    def initialize(opts = {})
      super('accessionWF', 'release', opts)
    end

    def process_item(work_item)
      # We're simply satisfying a prerequisite, not doing any actual work
      return true
    end 
  end
end