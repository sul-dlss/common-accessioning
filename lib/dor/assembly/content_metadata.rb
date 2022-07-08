# frozen_string_literal: true

module Dor
  module Assembly
    VALID_STYLES = %i[simple_image simple_book file map 3d].freeze

    # This class generates content metadata for image files
    class ContentMetadata
      # Generates image content XML metadata for a repository object.
      # This method only produces content metadata for images
      # and does not depend on a specific folder structure.  Note that it is class level method.
      #
      # @param [Hash] params a hash containg parameters needed to produce content metadata
      #   :druid = required - a string of druid of the repository object's druid id (with or without 'druid:' prefix)
      #   :objects = required - an array of Assembly::ObjectFile objects containing the list of files to add to content metadata
      #                NOTE: if you set the :bundle option to :prebundled, you will need to pass in an array of arrays, and not a flat array, as noted below
      #   :style = optional - a symbol containing the style of metadata to create, allowed values are
      #                 :simple_image (default), contentMetadata type="image", resource type="image"
      #                 :file, contentMetadata type="file", resource type="file"
      #                 :simple_book, contentMetadata type="book", resource type="page", but any resource which has file(s) other than an image, and also contains no images at all, will be resource type="object"
      #                 :book_with_pdf, contentMetadata type="book", resource type="page", but any resource which has any file(s) other than an image will be resource type="object" - NOTE: THIS IS DEPRECATED
      #                 :book_as_image, as simple_book, but with contentMetadata type="book", resource type="image" (same rule applies for resources with non images)  - NOTE: THIS IS DEPRECATED
      #                 :map, like simple_image, but with contentMetadata type="map", resource type="image"
      #                 :3d, contentMetadata type="3d", ".obj" and other configured 3d extension files go into resource_type="3d", everything else into resource_type="file"
      #                 :webarchive-seed, contentMetadata type="webarchive-seed", resource type="image"
      #   :file_attributes = optional - a hash of file attributes by mimetype to use instead of defaults
      #             If a mimetype match is not found in your hash, the default is used (either your supplied default or the gems).
      #             e.g. {'default'=>{:preserve=>'yes',:shelve=>'yes',:publish=>'yes'},'image/tif'=>{:preserve=>'yes',:shelve=>'no',:publish=>'no'},'application/pdf'=>{:preserve=>'yes',:shelve=>'yes',:publish=>'yes'}}
      #   :include_root_xml = optional - a boolean to indicate if the contentMetadata returned includes a root <?xml version="1.0"?> tag, defaults to true
      #   :preserve_common_paths = optional - When creating the file "id" attribute, content metadata uses the "relative_path" attribute of the ObjectFile objects passed in.  If the "relative_path" attribute is not set,  the "path" attribute is used instead,
      #                   which includes a full path to the file. If the "preserve_common_paths" parameter is set to false or left off, then the common paths of all of the ObjectFile's passed in are removed from any "path" attributes.  This should turn full paths into
      #                   the relative paths that are required in content metadata file id nodes.  If you do not want this behavior, set "preserve_common_paths" to true.  The default is false.
      #   :auto_labels = optional - Will add automated resource labels (e.g. "File 1") when labels are not provided by the user.  The default is true.
      #   See https://consul.stanford.edu/pages/viewpage.action?spaceKey=chimera&title=DOR+content+types%2C+resource+types+and+interpretive+metadata for next two settings
      #   :reading_order = optional - only valid for simple_book, can be 'rtl' or 'ltr'.  The default is 'ltr'.
      # Example:
      #    Assembly::ContentMetadata.create_content_metadata(:druid=>'druid:nx288wh8889',:style=>:simple_image,:objects=>object_files)
      def self.create_content_metadata(druid:, objects:, auto_labels: true,
                                       style: :simple_image, file_attributes: {},
                                       preserve_common_paths: false, include_root_xml: nil,
                                       reading_order: 'ltr')
        common_path = find_common_path(objects) unless preserve_common_paths # find common paths to all files provided if needed

        filesets = FileSetBuilder.build(objects: objects, style: style)
        config = Config.new(auto_labels: auto_labels,
                            file_attributes: file_attributes,
                            reading_order: reading_order,
                            type: object_level_type(style))

        builder = NokogiriBuilder.build(druid: druid,
                                        filesets: filesets,
                                        common_path: common_path,
                                        config: config)

        if include_root_xml == false
          builder.doc.root.to_xml
        else
          builder.to_xml
        end
      end

      def self.find_common_path(objects)
        all_paths = objects.flatten.map do |obj|
          raise "File '#{obj.path}' not found" unless obj.file_exists?

          obj.path # collect all of the filenames into an array
        end

        ::Assembly::ObjectFile.common_path(all_paths) # find common paths to all files provided if needed
      end
      private_class_method :find_common_path

      def self.object_level_type(style)
        raise "Supplied style (#{style}) not valid" unless VALID_STYLES.include? style

        case style
        when :simple_image
          'image'
        when :simple_book, :book_with_pdf, :book_as_image
          'book'
        else
          style.to_s
        end
      end
    end
  end
end
