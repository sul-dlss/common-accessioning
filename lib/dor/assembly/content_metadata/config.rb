# frozen_string_literal: true

module Dor
  module Assembly
    class ContentMetadata
      # Types for the configuration
      module Types
        include Dry.Types()
      end

      # Represents a configuration for generating the content metadata
      class Config < Dry::Struct
        STYLES = %w[image file book map 3d document webarchive-seed].freeze
        READING_ORDERS = %w[ltr rtl].freeze
        attribute :auto_labels, Types::Strict::Bool.default(true)
        attribute :add_file_attributes, Types::Strict::Bool.default(false)
        attribute :add_exif, Types::Strict::Bool.default(false)
        attribute :file_attributes, Types::Strict::Hash.default({}.freeze)
        attribute :type, Types::Strict::String.enum(*STYLES)
        attribute :reading_order, Types::Strict::String.default('ltr').enum(*READING_ORDERS)
      end
    end
  end
end
