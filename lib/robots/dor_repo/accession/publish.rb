# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Sends initial metadata to PURL, in robots/release/release_publish we push
      # to PURL again with updates to identityMetadata
      class Publish < Robots::DorRepo::Base
        def initialize
          super('accessionWF', 'publish')
        end

        def perform(druid)
          object_client = Dor::Services::Client.object(druid)
          # `#find` returns an instance of a model from the cocina-models gem
          obj = object_client.find

          return LyberCore::Robot::ReturnState.new(status: :skipped, note: 'Admin policy objects are not published') if obj.admin_policy?

          # This is an asynchronous result. It will set the publish workflow to complete when it is done.
          object_client.publish(workflow: 'accessionWF', lane_id: lane_id(druid))
          LyberCore::Robot::ReturnState.new(status: :noop, note: 'Initiated publish API call.')
        end
      end
    end
  end
end
