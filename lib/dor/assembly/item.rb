# frozen_string_literal: true

module Dor
  module Assembly
    class Item
      include Dor::Assembly::ContentMetadata

      def initialize(params = {})
        # Takes a druid, either as a string or as a Druid object.
        # Always converts @druid to a Druid object.
        @druid = params[:druid]
        @druid = DruidTools::Druid.new(@druid) unless @druid.class == DruidTools::Druid
        @path_finder = PathFinder.new(druid_id: @druid.id)
        @path_finder.check_for_path
      end

      def cocina_model
        @cocina_model ||= Dor::Services::Client.object(druid.druid).find
      end

      def item?
        cocina_model.is_a?(Cocina::Models::DRO)
      end

      attr_reader :path_finder
    end
  end
end
