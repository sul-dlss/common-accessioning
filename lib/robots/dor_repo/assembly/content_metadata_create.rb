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

          return LyberCore::ReturnState.new(status: :skipped, note: 'No stubContentMetadata to load from the filesystem') unless assembly_item.stub_content_metadata_exists?

          updated = assembly_item.cocina_model.new(structural: assembly_item.convert_stub_content_metadata)
          assembly_item.object_client.update(params: updated)

          # Remove the stubContentMetadata.xml
          FileUtils.rm(assembly_item.stub_cm_file_name)

          LyberCore::ReturnState.new(status: 'completed')
        end
      end
    end
  end
end
