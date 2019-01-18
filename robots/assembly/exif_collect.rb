# frozen_string_literal: true

require_relative './base'

module Robots
  module DorRepo
    module Assembly
      class ExifCollect < Robots::DorRepo::Assembly::Base
        def initialize(opts = {})
          super('dor', 'assemblyWF', 'exif-collect', opts)
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
          # obj is a Assembly::ObjectFile
          assembly_item.fnode_tuples.each do |fn, obj|
            # always add certain attributes to file node regardless of type
            add_data_to_file_node fn, obj, assembly_item.default_file_attributes(obj)

            # now depending on the type of object in the file node (i.e. image vs pdf) add other attributes to resource content metadata
            case obj.object_type

            when :image # when the object file type is an image
              fn.add_child(image_data_xml(obj.exif)) if fn.css('imageData').empty?

            else # all other object file types will force resource type to not be an image
              set_node_type fn.parent, 'file' # set the resource type to 'file' if it's not currently defined

            end
          end

          # set the root contentMetadata type to default to 'image' if it's not currently defined
          set_node_type assembly_item.cm.root, 'image'

          # Save the modified XML.
          assembly_item.persist_content_metadata
        end

        def set_node_type(node, node_type, overwrite = false)
          node['type'] = node_type if node['type'].blank? || overwrite # only set the node if it's not empty, unless we allow overwrite
        end

        def add_data_to_file_node(node, file, file_attributes)
          node['mimetype'] = file.mimetype unless node['mimetype']
          node['size'] = file.filesize.to_s unless node['size']

          # add publish/preserve/shelve attributes based on mimetype, unless they already exist in content metadata (use defaults if mimetype not found in mapping)
          %w[preserve publish shelve].each { |attribute| node[attribute] = file_attributes[attribute.to_sym] unless node[attribute] }
        end

        def image_data_xml(exif)
          w = exif.image_width
          h = exif.image_height
          %(<imageData width="#{w}" height="#{h}"/>)
        end
      end
    end
  end
end
