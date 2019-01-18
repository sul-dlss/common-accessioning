# frozen_string_literal: true

require_relative './base'

module Robots
  module DorRepo
    module Assembly
      class Jp2Create < Robots::DorRepo::Assembly::Base
        def initialize(opts = {})
          super('dor', 'assemblyWF', 'jp2-create', opts)
        end

        def perform(druid)
          with_item(druid) do |item|
            create_jp2s(item)
          end
        end

        private

        def create_jp2s(item)
          LyberCore::Log.info("Creating JP2s for #{item.druid.id}")

          # For each supported image type that is part of specific resource types, generate a jp2 derivative
          # and modify content metadata XML to reflect the new file.
          jp2able_fnode_tuples = []
          # grab all the file node tuples for each valid resource type that we want to generate derivates for
          Dor::Config.assembly.jp2_resource_types.each do |resource_type|
            jp2able_fnode_tuples += item.fnode_tuples(resource_type)
          end
          jp2able_fnode_tuples.each do |fn, obj|
            next unless obj.jp2able?

            create_jp2(fn, obj)
          end

          # Save the modified XML.
          item.persist_content_metadata
        end

        def create_jp2(file_node, obj)
          img = ::Assembly::Image.new(obj.path) # create a new image object from the object file so we can generate a jp2
          # (e.g. if oo000oo0001_05_00.jp2 exists and you call create_jp2 for oo000oo0001_00_00.tif, you will not create a new JP2, even though there would not be a filename clash)
          if !Dor::Config.assembly.overwrite_dpg_jp2 && File.exist?(img.dpg_jp2_filename) # don't fail this case, but log it
            message = "WARNING: Did not create jp2 for #{img.path} -- since another JP2 with the same DPG base name called #{img.dpg_jp2_filename} exists"
            LyberCore::Log.warn(message)
          # if we have an existing jp2 with the same basename as the tiff -- don't fail, but do log it
          elsif !Dor::Config.assembly.overwrite_jp2 && File.exist?(img.jp2_filename)
            message = "WARNING: Did not create jp2 for #{img.path} -- file already exists"
            LyberCore::Log.warn(message)
          else
            tmp_folder = Dor::Config.assembly.tmp_folder || '/tmp'
            jp2       = img.create_jp2(overwrite: Dor::Config.assembly.overwrite_jp2, tmp_folder: tmp_folder)
            # generate new filename for jp2 file node in content metadata by replacing filename in base file node with new jp2 filename
            file_name = file_node['id'].gsub(File.basename(img.path), File.basename(jp2.path))
            add_jp2_file_node file_node.parent, file_name
          end
        end

        def add_jp2_file_node(parent_node, file_name)
          # Adds a file node representing the new jp2 file.
          f = %(<file id="#{file_name}" />)
          parent_node.add_child f
        end
      end
    end
  end
end
