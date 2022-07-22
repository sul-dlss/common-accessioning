# frozen_string_literal: true

require 'active_support/core_ext/object/blank'

module Dor
  module Assembly
    module ContentMetadataFromStub
      # Represents a groups of related Files, such as a single master file and the derivatives
      class FileSet
        # if input file has one of these extensions in a 3D object, it will get the 3d resource type
        VALID_THREE_DIMENSION_EXTENTIONS = ['.obj'].freeze

        # @param [Cocina::Models::DRO] cocina_model
        # @param [Array<Assembly::ObjectFile>] resource_files
        def initialize(resource_files:, cocina_model:)
          @resource_files = resource_files
          @cocina_model = cocina_model
        end

        def label_from_file(default:)
          resource_files.find { |obj| obj.label.present? }&.label || default
        end

        attr_reader :resource_files

        # use object type to determine the file set type
        def file_set_type
          case @cocina_model.type
          when Cocina::Models::ObjectType.book
            resource_file_types = resource_files.collect(&:object_type)
            # grab all of the file types within a resource into an array so we can decide what the resource type should be
            resource_has_non_images = !(resource_file_types - [:image]).empty?
            resource_has_non_images && resource_file_types.include?(:image) == false ? 'object' : 'page'
          when Cocina::Models::ObjectType.image, Cocina::Models::ObjectType.map
            'image'
          when Cocina::Models::ObjectType.object
            'file'
          when Cocina::Models::ObjectType.three_dimensional
            resource_extensions = resource_files.collect(&:ext)
            if (resource_extensions & VALID_THREE_DIMENSION_EXTENTIONS).empty? # if this resource contains no known 3D file extensions, the resource type is file
              'file'
            else # otherwise the resource type is 3d
              '3d'
            end
          else
            raise "Unexpected type '#{@cocina_model.type}'"
          end
        end
      end
    end
  end
end
