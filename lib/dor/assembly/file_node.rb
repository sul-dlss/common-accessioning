# frozen_string_literal: true

module Dor
  module Assembly
    class FileNode
      # @param [Nokogiri::XML::Element] xml_node
      def initialize(xml_node:)
        @xml_node = xml_node
      end

      def size=(size)
        xml_node['size'] = size.to_s unless xml_node['size']
      end

      def mimetype=(mimetype)
        xml_node['mimetype'] = mimetype unless xml_node['mimetype']
      end

      # add publish/preserve/shelve attributes based on mimetype,
      # unless they already exist in content metadata (use defaults if mimetype not found in mapping)
      def add_defaults(mimetype)
        defaults = Dor::Assembly::Item.default_file_attributes(mimetype)
        defaults.each { |key, default| xml_node[key.to_s] ||= default }
      end

      def add_image_data(exif_data)
        return if xml_node.css(ImageDataNode::NODE_NAME).present?

        xml_node.add_child(ImageDataNode.build(exif_data))
      end

      private

      attr_reader :xml_node
    end
  end
end
