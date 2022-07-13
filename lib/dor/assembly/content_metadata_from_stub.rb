# frozen_string_literal: true

module Dor
  module Assembly
    # This class generates content metadata XML from stubContentMetadata
    class ContentMetadataFromStub
      # Generates image content XML metadata for a repository object.
      #
      # @param [Hash] params a hash containg parameters needed to produce content metadata
      #   :druid = required - a string of druid of the repository object's druid id (with or without 'druid:' prefix)
      #   :objects = required - an array of Assembly::ObjectFile objects containing the list of files to add to content metadata
      #                NOTE: if you set the :bundle option to :prebundled, you will need to pass in an array of arrays, and not a flat array, as noted below
      #   :object_type a string containing the object type of metadata to create, allowed values are
      #                 image contentMetadata type="image", resource type="image"
      #                 file, contentMetadata type="file", resource type="file"
      #                 book, contentMetadata type="book", resource type="page", but any resource which has file(s) other than an image, and also contains no images at all, will be resource type="object"
      #                 map, like simple_image, but with contentMetadata type="map", resource type="image"
      #                 3d, contentMetadata type="3d", ".obj" and other configured 3d extension files go into resource_type="3d", everything else into resource_type="file"
      #   See https://consul.stanford.edu/pages/viewpage.action?spaceKey=chimera&title=DOR+content+types%2C+resource+types+and+interpretive+metadata for next two settings
      #   :reading_order = optional - only valid for simple_book, can be 'rtl' or 'ltr'.  The default is 'ltr'.
      # Example:
      #    Assembly::ContentMetadata.create_content_metadata(:druid=>'druid:nx288wh8889', object_type: 'image' ,:objects=>object_files)
      def self.create_content_metadata(druid:, objects:, object_type: 'image', reading_order: 'ltr')
        common_path = find_common_path(objects) # find common paths to all files provided

        filesets = objects.map { |resource_files| FileSet.new(resource_files: resource_files, object_type: object_type) }

        NokogiriBuilder.build(druid: druid,
                              filesets: filesets,
                              common_path: common_path,
                              reading_order: reading_order,
                              object_type: object_type).to_xml
      end

      def self.find_common_path(objects)
        all_paths = objects.flatten.map do |obj|
          raise "File '#{obj.path}' not found" unless obj.file_exists?

          obj.path # collect all of the filenames into an array
        end

        ::Assembly::ObjectFile.common_path(all_paths) # find common paths to all files provided if needed
      end
      private_class_method :find_common_path
    end
  end
end
