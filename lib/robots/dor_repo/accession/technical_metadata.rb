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
          object_client = Dor::Services::Client.object(druid)
          obj = object_client.find

          # non-items don't generate contentMetadata
          return unless obj.dro?

          object = DruidTools::Druid.new(druid, Dor::Config.stacks.local_workspace_root)
          path = object.find_metadata('technicalMetadata.xml')

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
            tech_md = generate_technical_metadata(druid)
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

        private

        def generate_technical_metadata(druid)
          obj = Dor.find(druid)
          tech_xml = obj.technicalMetadata.content unless obj.technicalMetadata.new?
          content_xml = obj.contentMetadata.content
          inventory_diff = Preservation::Client.objects.content_inventory_diff(druid: druid, content_metadata: content_xml)

          files = obj.contentMetadata.ng_xml.xpath('//file/@id').map(&:content)
          TechnicalMetadataService.add_update_technical_metadata(files: files,
                                                                 pid: druid,
                                                                 tech_metadata: tech_xml,
                                                                 preservation_technical_metadata: preservation_technical_metadata(druid),
                                                                 content_group_diff: inventory_diff.group_difference('content'))
        end

        # @return [String] The datastream contents from the previous version of the digital object (fetched from preservation),
        #   or nil if there is no such datastream (e.g. object not yet in preservation)
        def preservation_technical_metadata(pid)
          Preservation::Client.objects.metadata(druid: pid, filepath: 'technicalMetadata.xml')
        rescue Preservation::Client::NotFoundError
          nil
        end
      end
    end
  end
end
