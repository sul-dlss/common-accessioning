# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class Jp2Create < Robots::DorRepo::Assembly::Base
        def initialize
          super('assemblyWF', 'jp2-create')
        end

        def perform_work
          return unless check_assembly_item

          cocina_model = assembly_item.cocina_model
          return LyberCore::ReturnState.new(status: :skipped, note: 'object is dark, no derivatives required') if cocina_model.access.view == 'dark'

          file_sets = create_jp2s(assembly_item, cocina_model)
          # Save the modified metadata
          updated = cocina_model.new(structural: cocina_model.structural.new(contains: file_sets))
          assembly_item.object_client.update(params: updated)
        end

        private

        # For each supported image type that is part of specific resource types, generate a jp2 derivative
        # and modify structural metadata to reflect the new file.
        # grab all the file node tuples for each valid resource type that we want to generate derivates for
        def create_jp2s(assembly_item, cocina_model)
          logger.info("Creating JP2s for #{assembly_item.druid.id}")
          file_sets = cocina_model.structural.to_h.fetch(:contains) # make this a mutable hash
          file_sets.each do |file_set|
            next unless [Cocina::Models::FileSetType.page, Cocina::Models::FileSetType.image].include?(file_set.fetch(:type))

            files = file_set.dig(:structural, :contains)

            tuples_to_add = []
            files.each do |file|
              object_file = ::Assembly::ObjectFile.new(assembly_item.path_finder.path_to_content_file(file.fetch(:filename)))

              next unless object_file.jp2able?

              img = ::Assembly::Image.new(object_file.path)
              tuples_to_add << [file, img]
            end

            if tuples_to_add.present?
              # Remove existing jp2 nodes
              files.delete_if { |file| file.fetch(:filename).ends_with?('.jp2') }
            end

            tuples_to_add.each do |(file, assembly_image)|
              create_jp2(file, file_set, assembly_image, cocina_model)
            end
          end

          file_sets
        end

        def create_jp2(file_node, file_set, assembly_image, cocina_model)
          file_name = if File.exist?(assembly_image.jp2_filename)
                        # if we have an existing jp2 with the same basename as the tiff -- don't fail, but do log it
                        #  this can happen if a user provides jp2 files as part of the accessioning process
                        #  (for example, if they were generated in a specific way ahead of time).
                        #  in this case, we do not want to overwrite the files provided with newly derived jp2s
                        message = "WARNING: Did not create jp2 for #{assembly_image.path} -- file already exists"
                        logger.warn(message)
                        new_jp2_file_name(file_node, assembly_image.jp2_filename, assembly_image.path)
                      else
                        tmp_folder = Settings.assembly.tmp_folder
                        jp2 = assembly_image.create_jp2(overwrite: false, tmp_folder: tmp_folder)
                        new_jp2_file_name(file_node, jp2.path, assembly_image.path)
                      end
          add_jp2_file_node(file_set, cocina_model, file_name)
        end

        # generate new filename for jp2 file node in content metadata by replacing filename in base file node with new jp2 filename
        def new_jp2_file_name(file_node, jp2_path, tiff_path)
          file_node.fetch(:filename).gsub(File.basename(tiff_path), File.basename(jp2_path))
        end

        def add_jp2_file_node(file_set, cocina_model, file_name)
          file_attributes = {
            type: 'https://cocina.sul.stanford.edu/models/file',
            externalIdentifier: "https://cocina.sul.stanford.edu/file/#{SecureRandom.uuid}",
            version: cocina_model.version,
            label: file_name,
            filename: file_name,
            hasMessageDigests: [],
            hasMimeType: 'image/jp2',
            administrative: { sdrPreserve: false, publish: true, shelve: true },
            access: Dor::FileSets.file_access(cocina_model.access)
          }

          # Adds a file node representing the new jp2 file.
          file_set.dig(:structural, :contains) << file_attributes
        end
      end
    end
  end
end
