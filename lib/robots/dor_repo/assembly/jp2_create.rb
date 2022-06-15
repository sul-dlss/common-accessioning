# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class Jp2Create < Robots::DorRepo::Assembly::Base
        def initialize
          super('assemblyWF', 'jp2-create')
        end

        def perform(druid)
          with_item(druid) do |assembly_item|
            create_jp2s(assembly_item)
          end
        end

        private

        def create_jp2s(assembly_item)
          LyberCore::Log.info("Creating JP2s for #{assembly_item.druid.id}")

          # For each supported image type that is part of specific resource types, generate a jp2 derivative
          # and modify content metadata XML to reflect the new file.
          jp2able_fnode_tuples = []
          # grab all the file node tuples for each valid resource type that we want to generate derivates for
          %w[page image].each do |resource_type|
            jp2able_fnode_tuples += assembly_item.fnode_tuples(resource_type)
          end
          jp2able_fnode_tuples.each do |file_node, object_file|
            next unless object_file.jp2able?

            create_jp2(file_node, object_file)
          end

          # Save the modified XML.
          assembly_item.persist_content_metadata
        end

        def create_jp2(file_node, object_file)
          img = ::Assembly::Image.new(object_file.path) # create a new image object from the object file so we can generate a jp2
          # (e.g. if oo000oo0001_05_00.jp2 exists and you call create_jp2 for oo000oo0001_00_00.tif, you will not create a new JP2, even though there would not be a filename clash)
          if File.exist?(img.dpg_jp2_filename) # don't fail this case, but log it
            message = "WARNING: Did not create jp2 for #{img.path} -- since another JP2 with the same DPG base name called #{img.dpg_jp2_filename} exists"
            LyberCore::Log.warn(message)
            add_jp2_file_node(file_node, img.dpg_jp2_filename, img.path)
          # if we have an existing jp2 with the same basename as the tiff -- don't fail, but do log it
          elsif File.exist?(img.jp2_filename)
            message = "WARNING: Did not create jp2 for #{img.path} -- file already exists"
            LyberCore::Log.warn(message)
            add_jp2_file_node(file_node, img.jp2_filename, img.path)
          else
            tmp_folder = Settings.assembly.tmp_folder
            jp2 = img.create_jp2(overwrite: false, tmp_folder: tmp_folder)
            add_jp2_file_node(file_node, jp2.path, img.path)
          end
        end

        def add_jp2_file_node(file_node, file_path, img_path)
          parent_node = file_node.parent
          return unless parent_node

          # generate new filename for jp2 file node in content metadata by replacing filename in base file node with new jp2 filename
          file_name = file_node['id'].gsub(File.basename(img_path), File.basename(file_path))

          # Remove existing jp2 nodes
          parent_node.xpath('file').each { |child_node| child_node.remove if child_node[:id].ends_with?('.jp2') }

          # Adds a file node representing the new jp2 file.
          parent_node.add_child %(<file id="#{file_name}" />)
        end
      end
    end
  end
end
