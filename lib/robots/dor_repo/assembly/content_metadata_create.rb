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
        def perform(druid)
          obj =  item(druid)
          return LyberCore::Robot::ReturnState.new(status: :skipped, note: 'object is not an item') unless obj.item? # not an item, skip

          return LyberCore::Robot::ReturnState.new(status: :skipped, note: 'No contentMetadata to load from the filesystem') if !content_metadata_exists?(obj) && !obj.stub_content_metadata_exists?

          # both stub and regular content metadata exist -- this is an ambiguous situation and generates an error
          raise "#{Settings.assembly.stub_cm_file_name} and #{Settings.assembly.cm_file_name} both exist for #{druid}" if obj.stub_content_metadata_exists? && content_metadata_exists?(obj)

          structural = if obj.stub_content_metadata_exists?
                         obj.convert_stub_content_metadata
                       else
                         # handle contentMetadata.xml
                         xml = File.read(cm_file_name(obj))
                         # Convert the XML to cocina and save it
                         Dor::StructuralMetadata.update(xml, obj.cocina_model)
                       end

          updated = obj.cocina_model.new(structural: structural)
          obj.object_client.update(params: updated)

          # Remove the contentMetadata.xml or stubContentMetadata.xml
          FileUtils.rm(cm_file_name(obj)) if content_metadata_exists?(obj)
          FileUtils.rm(obj.stub_cm_file_name) if obj.stub_content_metadata_exists?

          LyberCore::Robot::ReturnState.new(status: 'completed')
        end

        # return the location to store or load the contentMetadata.xml file (could be in either the new or old location)
        def cm_file_name(obj)
          @cm_file_name ||= obj.path_finder.path_to_metadata_file(Settings.assembly.cm_file_name)
        end

        def content_metadata_exists?(obj)
          # indicate if a contentMetadata file exists
          File.exist?(cm_file_name(obj))
        end
      end
    end
  end
end
