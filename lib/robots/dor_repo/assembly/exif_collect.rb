# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class ExifCollect < Robots::DorRepo::Assembly::Base
        def initialize(opts = {})
          super('assemblyWF', 'exif-collect', opts)
        end

        def perform(druid)
          with_item(druid) do |assembly_item|
            collect_exif_info(assembly_item)
          end
        end

        private

        def collect_exif_info(assembly_item)
          LyberCore::Log.info("Collecting exif info for #{assembly_item.druid}")

          # fn is a Nokogiri::XML::Element representing a file node
          # object_file is a Assembly::ObjectFile
          assembly_item.fnode_tuples.each do |fn, object_file|
            file_node = Dor::Assembly::FileNode.new(xml_node: fn)
            assign_exif_to_file(file_node: file_node,
                                filesize: object_file.filesize,
                                mimetype: object_file.mimetype)

            # now depending on the type of object in the file node (i.e. image vs pdf) add other attributes to resource content metadata
            case object_file.object_type

            when :image # when the object file type is an image
              file_node.add_image_data(object_file.exif)
            else # all other object file types will force resource type to not be an image
              set_node_type fn.parent, 'file' # set the resource type to 'file' if it's not currently defined
            end
          end

          # set the root contentMetadata type to default to 'image' if it's not currently defined
          set_node_type assembly_item.cm.root, 'image'

          # Save the modified XML.
          assembly_item.persist_content_metadata
        end

        # TODO: It would be great if we could avoid this step if the file node already
        # had size, mimetype and defaults. This can be slow because it runs file
        # and or exiftool on each file
        def assign_exif_to_file(file_node:, filesize:, mimetype:)
          file_node.size = filesize
          file_node.mimetype = mimetype
          file_node.add_defaults(mimetype)
        end

        def set_node_type(node, node_type, overwrite = false)
          node['type'] = node_type if node['type'].blank? || overwrite # only set the node if it's not empty, unless we allow overwrite
        end
      end
    end
  end
end
