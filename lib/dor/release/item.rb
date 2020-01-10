# frozen_string_literal: true

require 'retries'
require 'dor-fetcher'

module Dor
  module Release
    class Item
      attr_accessor :druid

      def initialize(druid:)
        # Takes a druid, either as a string or as a Druid object.
        @druid = druid
      end

      def object
        @object ||= Dor.find(@druid)
      end

      def object_type
        unless @obj_type
          obj_type = object.identityMetadata.objectType
          @obj_type = (obj_type.nil? ? 'unknown' : obj_type.first)
        end
        @obj_type.downcase.strip
      end
    end
  end
end
