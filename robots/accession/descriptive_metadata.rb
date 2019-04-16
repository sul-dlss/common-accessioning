# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates the descMetadata datastream
      class DescriptiveMetadata < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'descriptive-metadata')
        end

        def perform(druid)
          obj = Dor.find(druid)
          builder = DatastreamBuilder.new(object: obj,
                                          datastream: obj.descMetadata,
                                          required: true)
          builder.build do |ds|
            obj.build_descMetadata_datastream(ds)
          end
        end
      end
    end
  end
end
