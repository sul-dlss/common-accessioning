# frozen_string_literal: true

require 'assembly-objectfile'

module Dor
  module Assembly
    module ContentMetadata
      attr_accessor :cm, :stub_cm, :druid, :root_dir

      # return the location to store or load the contentMetadata.xml file (could be in either the new or old location)
      def cm_file_name
        @cm_file_name ||= path_finder.path_to_metadata_file(Settings.assembly.cm_file_name)
      end

      def content_metadata_exists?
        # indicate if a contentMetadata file exists
        File.exist?(cm_file_name)
      end

      # rubocop:disable Naming/MemoizedInstanceVariableName
      def load_content_metadata
        # Loads content metadata XML into a Nokogiri document.
        raise "Content metadata file #{Settings.assembly.cm_file_name} not found for #{druid.id} in any of the root directories: #{@root_dir.join(',')}" unless content_metadata_exists?

        @cm ||= Nokogiri.XML(File.open(cm_file_name)) { |conf| conf.default_xml.noblanks }
      end
      # rubocop:enable Naming/MemoizedInstanceVariableName

      def persist_content_metadata
        # Writes content metadata XML to the content metadata file
        xml = @cm.to_xml
        return if xml.blank?

        File.open(cm_file_name, 'w') { |f| f.puts xml }
      end

      def new_node_in_cm(node_name)
        # Returns a new node with the supplied name (with the GC lifecycle of
        # the content metadata document).
        Nokogiri::XML::Node.new node_name, @cm
      end

      def file_nodes(resource_type = '')
        # Returns all Nokogiri <file> nodes from content metadata, optionally restricted to specific resource content types if specified
        xpath_query = '//resource'
        xpath_query += "[@type='#{resource_type}']" unless resource_type == ''
        xpath_query += '/file'
        cm.xpath xpath_query
      end

      def fnode_tuples(resource_type = '')
        # Returns a list of filenode pairs (file node and associated ObjectFile object), optionally restricted to specific resource content types if specified
        file_nodes(resource_type).map { |fn| [fn, ::Assembly::ObjectFile.new(path_finder.path_to_content_file(fn['id']))] }
      end
    end
  end
end
