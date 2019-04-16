# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates the contentMetadata datastream
      class ContentMetadata < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'content-metadata')
        end

        def perform(druid)
          obj = Dor.find(druid)
          builder = DatastreamBuilder.new(object: obj,
                                          datastream: obj.contentMetadata,
                                          force: true)
          builder.build
        end
      end
    end
  end
end
