# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

module Dor
  module Assembly
    class ContentMetadata
      # Represents a single File
      class File
        # @param [Symbol] bundle
        # @param [Assembly::ObjectFile] file
        # @param style
        def initialize(file:, bundle: nil, style: nil)
          @bundle = bundle
          @file = file
          @style = style
        end

        delegate :sha1, :md5, :mimetype, :filesize, :image?, :valid_image?, to: :file

        def file_id(common_path:)
          # set file id attribute, first check the relative_path parameter on the object, and if it is set, just use that
          return file.relative_path if file.relative_path

          # if the relative_path attribute is not set, then use the path attribute and check to see if we need to remove the common part of the path
          common_path ? file.path.gsub(common_path, '') : file.path
        end

        delegate :file_attributes, to: :file

        def image_data
          { height: file.exif.imageheight, width: file.exif.imagewidth }
        end

        private

        attr_reader :file
      end
    end
  end
end
