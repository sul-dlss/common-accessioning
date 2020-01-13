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

          # Since not being published, need to set publish-complete so that will proceed with wf.
          if obj.is_a?(Cocina::Models::AdminPolicy)
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
