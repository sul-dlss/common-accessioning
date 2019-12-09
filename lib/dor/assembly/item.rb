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

      def object
        @object ||= Dor.find(@druid.druid)
      end

      def object_type
        obj_type = object.identityMetadata.objectType
        (obj_type.nil? ? 'unknown' : obj_type.first)
      end

      def item?
        object_type.downcase.strip == 'item'
      end

      attr_reader :path_finder
    end
  end
end
