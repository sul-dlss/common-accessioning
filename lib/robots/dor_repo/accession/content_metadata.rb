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
          return unless obj.is_a?(Dor::Item)

          DatastreamBuilder.new(datastream: obj.contentMetadata).build do |ds|
            # No-op
          end
        end
      end
    end
  end
end
