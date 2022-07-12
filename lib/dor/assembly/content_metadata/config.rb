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
        attribute :type, Types::Strict::String.enum(*STYLES)
        attribute :reading_order, Types::Strict::String.default('ltr').enum(*READING_ORDERS)
      end
    end
  end
end
