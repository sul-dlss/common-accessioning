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

      # actual path to object, found by iterating through all possible root paths and looking first for the new druid tree path, then for the old druid path
      #  return nil if not found anywhere
      def path_to_object
        return @path_to_object unless @path_to_object.nil?

        path = nil
        root_dir.each do |root_dir|
          new_path = druid_tree_path(root_dir)
          old_path = old_druid_tree_path(root_dir)
          if File.directory? new_path
            path = new_path
            @folder_style = :new
            break
          elsif File.directory? old_path
            path = old_path
            @folder_style = :old
            break
          end
        end
        @path_to_object = path
      end

      # path to a content folder, defaults to new (aa/111/bb/2222/bb111bb2222/content), but could also be old style (aa/111/bb/2222)
      def path_to_content_folder
        folder_style == :old ? path_to_object : File.join(path_to_object, 'content')
      end

      # path to a content file, e.g.  either aa/111/bb/2222/bb111bb2222/content/some_file.txt or  aa/111/bb/2222/some_file.txt
      def path_to_content_file(filename)
        File.join path_to_content_folder, filename
      end

      # path to a content file, e.g.  either aa/111/bb/2222/bb111bb2222/metadata/some_file.xml or  aa/111/bb/2222/some_file.xml
      def path_to_metadata_file(filename)
        File.join path_to_metadata_folder, filename
      end

      private

      attr_reader :folder_style, :druid_id

      def root_dir
        Array(Settings.assembly.root_dir)
      end

      # new style path, e.g. aa/111/bb/2222/bb111bb2222
      def druid_tree_path(root_dir)
        DruidTools::Druid.new(druid_id, root_dir).path
      end

      # old style path, e.g. aa/111/bb/2222
      def old_druid_tree_path(root_dir)
        File.dirname druid_tree_path(root_dir)
      end

      # path to a metadata folder, defaults to new (aa/111/bb/2222/bb111bb2222/metadata), but could also be old style (aa/111/bb/2222)
      def path_to_metadata_folder
        folder_style == :old ? path_to_object : File.join(path_to_object, 'metadata')
      end
    end
  end
end
