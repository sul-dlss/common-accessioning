# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates the rightsMetadata datastream
      class RightsMetadata < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'rights-metadata')
        end

        def perform(druid)
          object = DruidTools::Druid.new(druid, Dor::Config.stacks.local_workspace_root)
          path = object.find_metadata('rightsMetadata.xml')
          object_client = Dor::Services::Client.object(druid)
          if path
            object_client.metadata.legacy_update(
              rights: {
                updated: File.mtime(path),
                content: File.read(path)
              }
            )
          elsif has_no_rights_metadata?(druid)
            Honeybadger.notify("I don't think this ever happens because rights is created when registering. This is an experiment")

            # TODO: Fetch admin_policy_object without involving Fedora 3 concepts
            apo = Dor.find(druid).admin_policy_object
            object_client.metadata.legacy_update(
              rights: {
                updated: Time.now,
                content: apo.defaultObjectRights.content
              }
            )
          end
        end

        # TODO: for now we're looking for the presence of the datastream, but eventually
        # we need to do this without involving Fedora 3 concepts
        def has_no_rights_metadata?(druid)
          Dor.find(druid).rightsMetadata.new?
        end
      end
    end
  end
end
