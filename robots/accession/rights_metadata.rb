# frozen_string_literal: true

# Initialize contentMetadata

module Robots
  module DorRepo
    module Accession

      class RightsMetadata < AbstractMetadata
        def self.params
          { :process_name => 'rights-metadata', :datastream => 'rightsMetadata' }
        end
      end

    end
  end
end
