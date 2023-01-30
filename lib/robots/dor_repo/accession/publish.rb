# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Sends initial metadata to PURL, in robots/release/release_publish we push
      # to PURL again with updates to identityMetadata
      class Publish < LyberCore::Robot
        def initialize
          super('accessionWF', 'publish')
        end

        def perform_work
          return LyberCore::ReturnState.new(status: :skipped, note: 'Admin policy objects are not published') if cocina_object.admin_policy?

          # This is an asynchronous result. It will set the publish workflow to complete when it is done.
          object_client.publish(workflow: 'accessionWF', lane_id: lane_id)
          LyberCore::ReturnState.new(status: :noop, note: 'Initiated publish API call.')
        end
      end
    end
  end
end
