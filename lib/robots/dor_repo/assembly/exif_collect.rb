# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class ExifCollect < Robots::DorRepo::Assembly::Base
        def initialize
          super('assemblyWF', 'exif-collect')
        end

        def perform(druid)
          with_item(druid) do |assembly_item|
            cocina_model = assembly_item.cocina_model
            file_sets = collect_exif_info(assembly_item, cocina_model)
            # Save the modified metadata
            updated = cocina_model.new(structural: cocina_model.structural.new(contains: file_sets))
            assembly_item.object_client.update(params: updated)
          end
        end

        private

        def collect_exif_info(assembly_item, cocina_model)
          LyberCore::Log.info("Collecting exif info for #{assembly_item.druid}")
          file_sets = cocina_model.structural.to_h.fetch(:contains) # make this a mutable hash

          file_sets.each do |file_set|
            files = file_set.dig(:structural, :contains)

            files.each do |file|
              object_file = ::Assembly::ObjectFile.new(assembly_item.path_finder.path_to_content_file(file.fetch(:filename)))
              file[:size] = object_file.filesize if !file[:size] || file[:size].zero?
              file[:hasMimeType] ||= object_file.mimetype

              next unless object_file.image?

              file[:presentation] = { height: object_file.exif.imageheight, width: object_file.exif.imagewidth }
            end
          end

          file_sets
        end
      end
    end
  end
end
