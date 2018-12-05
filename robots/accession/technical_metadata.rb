# frozen_string_literal: true

# Initialize technicalMetadata

module Robots
  module DorRepo
    module Accession

      class TechnicalMetadata < AbstractMetadata
        def self.params
          { :process_name => 'technical-metadata', :datastream => 'technicalMetadata', :force => true }
        end
      end

    end
  end
end
