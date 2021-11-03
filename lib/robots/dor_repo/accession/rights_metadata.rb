# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates the rightsMetadata datastream
      class RightsMetadata < Robots::DorRepo::Base
        def initialize
          super('accessionWF', 'rights-metadata')
        end

        def perform(druid)
          object = DruidTools::Druid.new(druid, Settings.stacks.local_workspace_root)
          path = object.find_metadata('rightsMetadata.xml')
          return LyberCore::Robot::ReturnState.new(status: :skipped, note: 'No rightsMetadata.xml was provided') unless path

          Honeybadger.notify("[WARN] We don't think that anything uses this robot. It is slated for removal", context: { druid: druid })

          object_client = Dor::Services::Client.object(druid)
          object_client.metadata.legacy_update(
            rights: {
              updated: File.mtime(path),
              content: File.read(path)
            }
          )
        end
      end
    end
  end
end
