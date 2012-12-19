# Initialize contentMetadata

module Accession
  
  class DescriptiveMetadata < AbstractMetadata
    def self.params
      { :process_name => 'descriptive-metadata', :datastream => 'descMetadata' }
    end
  end
end