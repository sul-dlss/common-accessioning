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
          builder = DatastreamBuilder.new(object: obj,
                                          datastream: obj.technicalMetadata,
                                          force: true)
          builder.build
        end
      end
    end
  end
end
