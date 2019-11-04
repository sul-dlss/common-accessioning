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

          return if obj.is_a?(Cocina::Models::AdminPolicy)

          # This is an async result and it will have a callback.
          object_client.publish(workflow: 'accessionWF')
        end
      end
    end
  end
end
