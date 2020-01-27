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

      def cocina_model
        @cocina_model ||= Dor::Services::Client.object(@druid).find
      end

      def collection?
        cocina_model.is_a?(Cocina::Models::Collection)
      end
    end
  end
end
