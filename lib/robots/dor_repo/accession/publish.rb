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

          # `#find` returns an instance of a model from the cocina-models gem
          if object_client.find.admin_policy?
            # Since admin policies are not published, we need to manually set
            # the publish-complete step to completed so that the workflow will
            # proceed.
            workflow_service.update_status(druid: druid, workflow: @workflow_name, process: 'publish-complete', status: 'completed', elapsed: 1, note: 'APOs are not published, so marking completed.')
            return
          end

          # This is an async result and it will have a callback.
          object_client.publish(workflow: 'accessionWF')
        end
      end
    end
  end
end
