# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates structural metadata based on contentMetadata.xml
      # Needed by https://github.com/sul-dlss/gis-robot-suite/blob/main/lib/robots/dor_repo/gis_assembly/generate_content_metadata.rb
      # and https://github.com/sul-dlss/was_robot_suite/blob/2575d1d43e3c99a7e6cef28886b433f5a41e14ad/lib/robots/dor_repo/was_seed_preassembly/content_metadata_generator.rb#L12-L13
      class ContentMetadata < LyberCore::Robot
        def initialize
          super('accessionWF', 'content-metadata')
        end

        def perform_work
          # Objects that aren't items/DROs do not have content metadata attached
          return unless cocina_object.dro?

          path = druid_object.find_metadata('contentMetadata.xml')

          return LyberCore::ReturnState.new(status: :skipped, note: 'No contentMetadata.xml was provided') unless path

          updated = cocina_object.new(structural: Dor::StructuralMetadata.update(File.read(path), cocina_object))
          object_client.update(params: updated)
        end
      end
    end
  end
end
