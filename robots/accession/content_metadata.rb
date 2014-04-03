# Initialize contentMetadata

module Robots
  module DorRepo
    module Accession

      class ContentMetadata < AbstractMetadata
        def self.params
          { :process_name => 'content-metadata', :datastream => 'contentMetadata', :force => true }
        end
      end

    end
  end
end