# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates or updates the descMetadata datastream
      # it first looks for a file on disk if it's newer than the datastream.
      # otherwise if the datastream hasn't alredy been populated it calls Symphony
      class DescriptiveMetadata < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'descriptive-metadata')
        end

        def perform(druid)
          object = DruidTools::Druid.new(druid, Dor::Config.stacks.local_workspace_root)
          path = object.find_metadata('descMetadata.xml')
          object_client = Dor::Services::Client.object(druid)

          if path
            object_client.metadata.legacy_update(
              descriptive: {
                updated: File.mtime(path),
                content: File.read(path)
              }
            )
          else
            object_client.refresh_metadata
          end
        end
      end
    end
  end
end
