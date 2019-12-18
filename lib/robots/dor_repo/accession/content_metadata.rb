# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates the contentMetadata datastream
      class ContentMetadata < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'content-metadata')
        end

        def perform(druid)
          object_client = Dor::Services::Client.object(druid)
          obj = object_client.find

          # non-items don't attach contentMetadata
          return unless obj.is_a?(Cocina::Models::DRO)

          object = DruidTools::Druid.new(druid, Dor::Config.stacks.local_workspace_root)
          path = object.find_metadata('contentMetadata.xml')

          return unless path

          object_client.metadata.legacy_update(
            content: {
              updated: File.mtime(path),
              content: File.read(path)
            }
          )
        end
      end
    end
  end
end
