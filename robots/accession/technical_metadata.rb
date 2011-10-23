# Initialize technicalMetadata

module Accession
  
  class TechnicalMetadata < AbstractMetadata
    def self.params
      { :process_name => 'technical-metadata', :datastream => 'technicalMetadata', :force => true }
    end
  end
end