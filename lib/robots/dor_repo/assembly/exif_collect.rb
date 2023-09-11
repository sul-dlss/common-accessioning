# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class ExifCollect < Robots::DorRepo::Assembly::Base
        def initialize
          super('assemblyWF', 'exif-collect')
        end

        def perform_work
          return unless check_assembly_item

          cocina_model = assembly_item.cocina_model
          file_sets = collect_exif_infos(assembly_item, cocina_model)
          # Save the modified metadata
          updated = cocina_model.new(structural: cocina_model.structural.new(contains: file_sets))
          assembly_item.object_client.update(params: updated)
        end

        private

        def collect_exif_infos(assembly_item, cocina_model)
          logger.info("Collecting exif info for #{assembly_item.druid}")
          file_sets = cocina_model.structural.to_h.fetch(:contains) # make this a mutable hash

          file_sets.each do |file_set|
            files = file_set.dig(:structural, :contains)

            files.each do |file|
              collect_exif_info(file, assembly_item.path_finder.path_to_content_file(file.fetch(:filename)))
            end
          end

          file_sets
        end

        def collect_exif_info(file, filepath)
          # File is not changing, so use existing exif info
          return if !File.exist?(filepath) && file[:size] && file[:hasMimeType]

          object_file = ::Assembly::ObjectFile.new(filepath)
          file[:size] = object_file.filesize if !file[:size] || file[:size].zero?
          file[:hasMimeType] ||= object_file.mimetype

          # NOTE: Only include height/width presentation information for
          #       "valid" images as determined by the assembly-objectfile gem:
          #       TIFF, PNG, JPEG, JP2
          file[:presentation] = { height: object_file.exif.imageheight, width: object_file.exif.imagewidth } if object_file.valid_image?
        end
      end
    end
  end
end
