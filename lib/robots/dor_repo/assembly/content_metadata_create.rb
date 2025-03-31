# frozen_string_literal: true

require 'fileutils'

module Robots
  module DorRepo
    module Assembly
      class ContentMetadataCreate < Robots::DorRepo::Assembly::Base
        def initialize
          super('assemblyWF', 'content-metadata-create')
        end

        # Generate the structural metadata for this object from stub content metadata (if present).
        def perform_work
          return LyberCore::ReturnState.new(status: :skipped, note: 'object is not an item') unless assembly_item.item? # not an item, skip

          return LyberCore::ReturnState.new(status: :skipped, note: 'No stubContentMetadata to load from the filesystem') unless assembly_item.stub_content_metadata_exists?

          updated = assembly_item.cocina_model.new(structural: assembly_item.convert_stub_content_metadata)
          assembly_item.object_client.update(params: updated)

          # Backup the stubContentMetadata.xml
          FileUtils.mv(assembly_item.stub_cm_file_name, File.join('/dor/stopped', "#{druid}-#{Settings.assembly.stub_cm_file_name}"))

          LyberCore::ReturnState.new(status: 'completed')
        end
      end
    end
  end
end
