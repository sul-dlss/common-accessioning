# frozen_string_literal: true

require 'assembly-objectfile'

module Dor
  module Assembly
    module ContentMetadata
      attr_accessor :cm, :stub_cm, :cm_handle, :druid, :root_dir

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
        # Writes content metadata XML to the content metadata file or
        # to @cm_handle (the latter is used for testing purposes).
        xml = @cm.to_xml
        if @cm_handle
          @cm_handle.puts xml
        elsif !xml.blank?
          File.open(cm_file_name, 'w') { |f| f.puts xml }
        end
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

      def create_basic_content_metadata
        raise "Content metadata file #{Settings.assembly.cm_file_name} exists already for #{druid.id}" if content_metadata_exists?

        Honeybadger.notify("How are we getting here? Shouldn't pre-assembly have generated contentMetadata.xml (#{druid.id}) already?")

        LyberCore::Log.info("Creating basic content metadata for #{druid.id}")

        # get a list of files in content folder recursively and sort them
        files = Dir["#{path_finder.path_to_content_folder}/**/*"].reject { |file| File.directory? file }.sort
        return nil if files.empty? # only generate contentMetadata if there are files in the content folder, else return nil

        cm_resources = files.map { |file| ::Assembly::ObjectFile.new(file) }
        # uses the assembly-objectfile gem to create basic content metadata using a simple list of files found in the content folder
        xml = ::Assembly::ContentMetadata.create_content_metadata(druid: @druid.druid, style: :file, objects: cm_resources, bundle: :filename)
        @cm = Nokogiri.XML(xml)
        xml
      end
    end
  end
end
