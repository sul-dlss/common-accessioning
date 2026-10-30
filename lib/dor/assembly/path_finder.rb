# frozen_string_literal: true

module Dor
  module Assembly
    # This finds files associated with a Druid
    class PathFinder
      # @param [String] The non-namespaced druid identifier.
      def initialize(druid_id:)
        @druid_id = druid_id
      end

      def check_for_path
        raise "Path to object #{druid_id} not found in any of the root directories: #{root_dir.join(',')}" if path_to_object.nil?
      end

      # actual path to object (e.g. aa/111/bb/2222/aa111bb2222), found in the first root directory that has it
      #  return nil if not found anywhere
      def path_to_object
        @path_to_object ||= root_dir.map { |dir| druid_tree_path(dir) }.find { |path| File.directory?(path) }
      end

      # path to a content folder, e.g. aa/111/bb/2222/aa111bb2222/content
      def path_to_content_folder
        File.join(path_to_object, 'content')
      end

      # path to a content file, e.g. aa/111/bb/2222/aa111bb2222/content/some_file.txt
      def path_to_content_file(filename)
        File.join path_to_content_folder, filename
      end

      # path to a metadata file, e.g. aa/111/bb/2222/aa111bb2222/metadata/some_file.xml
      def path_to_metadata_file(filename)
        File.join path_to_object, 'metadata', filename
      end

      private

      attr_reader :druid_id

      def root_dir
        Array(Settings.assembly.root_dir)
      end

      def druid_tree_path(root_dir)
        DruidTools::Druid.new(druid_id, root_dir).path
      end
    end
  end
end
