# frozen_string_literal: true

module Dor::Assembly
  class Item
    include Dor::Assembly::ContentMetadata
    include Dor::Assembly::Checksumable
    include Dor::Assembly::Findable
    include Dor::Assembly::Identifiable

    def initialize(params = {})
      # Takes a druid, either as a string or as a Druid object.
      # Always converts @druid to a Druid object.
      @druid = params[:druid]
      @druid = DruidTools::Druid.new(@druid) unless @druid.class == DruidTools::Druid
      root_dir_config = Dor::Config.assembly.root_dir
      @root_dir = root_dir_config.class == String ? [root_dir_config] : root_dir_config # this allows us to accept either a string or an array of strings as a root dir configuration
      check_for_path
    end

    def object
      @fobj ||= Dor.find(@druid.druid)
    end

    def check_for_path
      raise "Path to object #{@druid.id} not found in any of the root directories: #{@root_dir.join(',')}" if path_to_object.nil?
    end
  end
end
