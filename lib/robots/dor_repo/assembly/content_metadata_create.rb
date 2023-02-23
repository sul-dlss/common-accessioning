# frozen_string_literal: true

require 'fileutils'

module Robots
  module DorRepo
    module Assembly
      class ContentMetadataCreate < Robots::DorRepo::Assembly::Base
        def initialize
          super('assemblyWF', 'content-metadata-create')
        end

        # generate the content metadata for this object based on some logic of whether
        # stub or regular content metadata already exists
        def perform_work
          return LyberCore::ReturnState.new(status: :skipped, note: 'object is not an item') unless assembly_item.item? # not an item, skip

          return LyberCore::ReturnState.new(status: :skipped, note: 'No contentMetadata to load from the filesystem') if !content_metadata_exists? && !assembly_item.stub_content_metadata_exists?

          # both stub and regular content metadata exist -- this is an ambiguous situation and generates an error
          raise "#{Settings.assembly.stub_cm_file_name} and #{Settings.assembly.cm_file_name} both exist for #{druid}" if assembly_item.stub_content_metadata_exists? && content_metadata_exists?

          structural = if assembly_item.stub_content_metadata_exists?
                         assembly_item.convert_stub_content_metadata
                       else
                         Honeybadger.notify('NOTE: assemblyWF#content-metadata-create robot converted contentMetadata.xml to Cocina. We are not sure this should happen anymore.')
                         # handle contentMetadata.xml
                         xml = File.read(cm_file_name)
                         # Convert the XML to cocina and save it
                         Dor::StructuralMetadata.update(xml, assembly_item.cocina_model)
                       end

          updated = assembly_item.cocina_model.new(structural: structural)
          assembly_item.object_client.update(params: updated)

          # Remove the contentMetadata.xml or stubContentMetadata.xml
          FileUtils.rm(cm_file_name) if content_metadata_exists?
          FileUtils.rm(assembly_item.stub_cm_file_name) if assembly_item.stub_content_metadata_exists?

          LyberCore::ReturnState.new(status: 'completed')
        end

        private

        # return the location to store or load the contentMetadata.xml file (could be in either the new or old location)
        def cm_file_name
          @cm_file_name ||= assembly_item.path_finder.path_to_metadata_file(Settings.assembly.cm_file_name)
        end

        def content_metadata_exists?
          # indicate if a contentMetadata file exists
          File.exist?(cm_file_name)
        end
      end
    end
  end
end
