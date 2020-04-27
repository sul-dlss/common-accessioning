# frozen_string_literal: true

module Dor
  module Assembly
    class Item
      include Dor::Assembly::ContentMetadata
      include Dor::Assembly::StubContentMetadataParser

      def initialize(params = {})
        # Takes a druid, either as a string or as a Druid object.
        # Always converts @druid to a Druid object.
        @druid = params[:druid]
        @druid = DruidTools::Druid.new(@druid) unless @druid.class == DruidTools::Druid
        @path_finder = PathFinder.new(druid_id: @druid.id)
        @path_finder.check_for_path
      end

      def cocina_model
        # `#find` returns an instance of a model from the cocina-models gem
        @cocina_model ||= Dor::Services::Client.object(druid.druid).find
      end

      def item?
        cocina_model.dro?
      end

      # @param [String] the mimetype of the file
      # @return [Hash<Symbol,String>] the default file attributes hash
      def self.default_file_attributes(mimetype)
        ::Assembly::ContentMetadata::File::ATTRIBUTES_FOR_TYPE.fetch(mimetype) { ::Assembly::ContentMetadata::File::ATTRIBUTES_FOR_TYPE.fetch('default') }
      end

      attr_reader :path_finder
    end
  end
end
