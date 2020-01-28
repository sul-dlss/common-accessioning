# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates the technicalMetadata datastream
      class TechnicalMetadata < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'technical-metadata')
        end

        def perform(druid)
          obj = Dor.find(druid)
          return unless obj.is_a?(Dor::Item)

          object = DruidTools::Druid.new(druid, Dor::Config.stacks.local_workspace_root)
          path = object.find_metadata('technicalMetadata.xml')
          object_client = Dor::Services::Client.object(druid)

          if path
            # When the technicalMetadata.xml file is found on the disk, use that
            object_client.metadata.legacy_update(
              technical: {
                updated: File.mtime(path),
                content: File.read(path)
              }
            )
          else
            # Otherwise (re)generate technical metadata
            xml = obj.technicalMetadata.content unless obj.technicalMetadata.new?
            tech_md = TechnicalMetadataService.add_update_technical_metadata(obj, pid: druid, tech_metadata: xml)
            if tech_md
              object_client.metadata.legacy_update(
                technical: {
                  updated: Time.now,
                  content: tech_md
                }
              )
            end
          end
        end
      end
    end
  end
end
