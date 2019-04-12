# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Sends initial metadata to PURL, in robots/release/release_publish we push
      # to PURL again with updates to identityMetadata
      class Publish < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'publish')
        end

        def perform(druid)
          obj = Dor.find(druid)
          return unless obj.is_a?(Dor::Set) || obj.is_a?(Dor::Item)

          PublishMetadataService.publish(obj)
        end
      end
    end
  end
end
