# frozen_string_literal: true

require 'active_support/core_ext/object/blank'

module Dor
  module Assembly
    class ContentMetadata
      # Represents a groups of related Files, such as a single master file and the derivatives
      class FileSet
        # if input file has one of these extensions in a 3D object, it will get the 3d resource type
        VALID_THREE_DIMENSION_EXTENTIONS = ['.obj'].freeze

        # @param style
        # @param [Array<Assembly::ObjectFile>] resource_files
        def initialize(resource_files:, style:)
          @resource_files = resource_files
          @style = style
        end

        # otherwise look at the style to determine the resource_type_description
        def resource_type_description
          @resource_type_description ||= resource_type_descriptions
        end

        def label_from_file(default:)
          resource_files.find { |obj| obj.label.present? }&.label || default
        end

        attr_reader :resource_files

        private

        attr_reader :style

        # use style attribute to determine the resource_type_description
        def resource_type_descriptions
          # grab all of the file types within a resource into an array so we can decide what the resource type should be
          resource_file_types = resource_files.collect(&:object_type)
          resource_has_non_images = !(resource_file_types - [:image]).empty?

          case style
          when :simple_image, :map
            'image'
          when :file
            'file'
          when :simple_book # in a simple book project, all resources are pages unless they are *all* non-images -- if so, switch the type to object
            resource_has_non_images && resource_file_types.include?(:image) == false ? 'object' : 'page'
          when :'3d'
            resource_extensions = resource_files.collect(&:ext)
            if (resource_extensions & VALID_THREE_DIMENSION_EXTENTIONS).empty? # if this resource contains no known 3D file extensions, the resource type is file
              'file'
            else # otherwise the resource type is 3d
              '3d'
            end
          end
        end
      end
    end
  end
end
