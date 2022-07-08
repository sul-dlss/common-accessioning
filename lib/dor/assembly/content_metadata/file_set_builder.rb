# frozen_string_literal: true

module Dor
  module Assembly
    class ContentMetadata
      # Builds a groups of related Files, based on bundle
      class FileSetBuilder
        # @param [Array<Assembly::ObjectFile>] objects
        # @param [Symbol] style one of: :simple_image, :file, :simple_book, :book_as_image, :book_with_pdf, :map, or :'3d'
        def self.build(objects:, style:)
          new(objects: objects, style: style).build
        end

        def initialize(objects:, style:)
          @objects = objects
          @style = style
        end

        # @return [Array<FileSet>] a list of filesets in the object
        def build
          # if the user specifies this method, they will pass in an array of arrays, indicating resources, so we don't need to bundle in the gem
          # This is used by the assemblyWF if you have stubContentMetadata.xml
          objects.map { |inner| FileSet.new(resource_files: inner, style: style) }
        end

        private

        attr_reader :objects, :style
      end
    end
  end
end
