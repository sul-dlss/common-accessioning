# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates or updates the descMetadata datastream
      # it first looks for a file on disk if it's newer than the datastream.
      # otherwise if the datastream hasn't alredy been populated it calls Symphony
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
            # If there's no file on disk that's newer than the datastream and
            # the datastream has never been populated, use Symphony:
            DescMetadataService.build(obj, ds)
          end
        end
      end
    end
  end
end
