# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates the technicalMetadata datastream
      class TechnicalMetadata < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'technical-metadata')
        end

        def perform(druid)
          obj = Dor.find(druid)
          return unless obj.is_a?(Dor::Item)

          builder = DatastreamBuilder.new(datastream: obj.technicalMetadata,
                                          force: true)
          builder.build do |_datastream|
            TechnicalMetadataService.add_update_technical_metadata(obj)
          end
        end
      end
    end
  end
end
