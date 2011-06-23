# Initialize contentMetadata

module Accession
  
  class RightsMetadata < AbstractMetadata
    def self.params
      { :process_name => 'rights-metadata', :datastream => 'rightsMetadata' }
    end
  end
end