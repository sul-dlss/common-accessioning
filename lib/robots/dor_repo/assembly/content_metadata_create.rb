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
        # rubocop:disable Metrics/MethodLength
        def perform_work
          return LyberCore::ReturnState.new(status: :skipped, note: 'object is not an item') unless assembly_item.item? # not an item, skip

          return LyberCore::ReturnState.new(status: :skipped, note: 'No stubContentMetadata to load from the filesystem') unless assembly_item.stub_content_metadata_exists?

          tries = 0
          max_tries = 3
          begin
            updated = assembly_item.cocina_model.new(structural: assembly_item.convert_stub_content_metadata)
            assembly_item.object_client.update(params: updated)
          # sometimes the stubContentMetadata.xml is in process of being written and is invalid
          # this is a workaround that gives it more time to complete
          # see https://github.com/sul-dlss/common-accessioning/issues/1477
          rescue RuntimeError => e
            tries += 1
            sleep((Settings.sleep_coefficient * 3)**tries)
            logger.info "Retry #{tries} for content-metadata-create; after exception #{e.message}"

            retry unless tries > max_tries
            raise e
          end

          # Remove the stubContentMetadata.xml
          FileUtils.rm(assembly_item.stub_cm_file_name)

          LyberCore::ReturnState.new(status: 'completed')
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
