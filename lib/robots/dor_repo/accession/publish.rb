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
          object_client = Dor::Services::Client.object(druid)
          obj = object_client.find

          object_client.publish unless obj.is_a?(Cocina::Models::AdminPolicy)
        end
      end
    end
  end
end
