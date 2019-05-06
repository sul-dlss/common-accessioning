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
                                          datastream: obj.descMetadata)
          builder.build do |_ds|
            # If there's no file on disk that's newer than the datastream and
            # the datastream has never been populated, use Symphony:
            Dor::Services::Client.object(druid).refresh_metadata
          end
        end
      end
    end
  end
end
