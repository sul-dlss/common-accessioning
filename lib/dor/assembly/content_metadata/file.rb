# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'

module Dor
  module Assembly
    class ContentMetadata
      # Represents a single File
      class File
        # @param [Assembly::ObjectFile] file
        def initialize(file:)
          @file = file
        end

        # Remove the common part of the path
        def file_id(common_path:)
          file.path.delete_prefix(common_path)
        end

        delegate :file_attributes, to: :file

        private

        attr_reader :file
      end
    end
  end
end
