# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

module Dor
  module Assembly
    class ContentMetadata
      # Represents a single File
      class File
        # default publish/preserve/shelve attributes used in content metadata
        # if no mimetype specific attributes are specified for a given file, define some defaults, and override for specific mimetypes below
        ATTRIBUTES_FOR_TYPE = {
          'default' => { preserve: 'yes', shelve: 'no', publish: 'no' },
          'image/tif' => { preserve: 'yes', shelve: 'no', publish: 'no' },
          'image/tiff' => { preserve: 'yes', shelve: 'no', publish: 'no' },
          'image/jp2' => { preserve: 'no', shelve: 'yes', publish: 'yes' },
          'image/jpeg' => { preserve: 'yes', shelve: 'no', publish: 'no' },
          'audio/wav' => { preserve: 'yes', shelve: 'no', publish: 'no' },
          'audio/x-wav' => { preserve: 'yes', shelve: 'no', publish: 'no' },
          'audio/mp3' => { preserve: 'no', shelve: 'yes', publish: 'yes' },
          'audio/mpeg' => { preserve: 'no', shelve: 'yes', publish: 'yes' },
          'application/pdf' => { preserve: 'yes', shelve: 'yes', publish: 'yes' },
          'plain/text' => { preserve: 'yes', shelve: 'yes', publish: 'yes' },
          'text/plain' => { preserve: 'yes', shelve: 'yes', publish: 'yes' },
          'image/png' => { preserve: 'yes', shelve: 'yes', publish: 'no' },
          'application/zip' => { preserve: 'yes', shelve: 'no', publish: 'no' },
          'application/json' => { preserve: 'yes', shelve: 'yes', publish: 'yes' }
        }.freeze

        # @param [Symbol] bundle
        # @param [Assembly::ObjectFile] file
        # @param style
        def initialize(file:, bundle: nil, style: nil)
          @bundle = bundle
          @file = file
          @style = style
        end

        delegate :sha1, :md5, :provider_md5, :provider_sha1, :mimetype, :filesize, :image?, :valid_image?, to: :file

        def file_id(common_path:)
          # set file id attribute, first check the relative_path parameter on the object, and if it is set, just use that
          return file.relative_path if file.relative_path

          # if the relative_path attribute is not set, then use the path attribute and check to see if we need to remove the common part of the path
          common_path ? file.path.gsub(common_path, '') : file.path
        end

        def file_attributes(provided_file_attributes)
          file.file_attributes || provided_file_attributes[mimetype] || provided_file_attributes['default'] || ATTRIBUTES_FOR_TYPE[mimetype] || ATTRIBUTES_FOR_TYPE['default']
        end

        def image_data
          { height: file.exif.imageheight, width: file.exif.imagewidth }
        end

        private

        attr_reader :file
      end
    end
  end
end
