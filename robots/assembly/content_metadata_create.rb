# frozen_string_literal: true

require_relative './base'

module Robots
  module DorRepo
    module Assembly
      class ContentMetadataCreate < Robots::DorRepo::Assembly::Base
        def initialize(opts = {})
          super('dor', 'assemblyWF', 'content-metadata-create', opts)
        end

        # generate the content metadata for this object based on some logic of whether
        # stub or regular content metadata already exists
        def perform(druid)
          obj =  item(druid)
          return LyberCore::Robot::ReturnState.new(status: :skipped, note: 'object is not an item') unless obj.item? # not an item, skip

          # both stub and regular content metadata exist -- this is an ambiguous situation and generates an error
          raise "#{Dor::Config.assembly.stub_cm_file_name} and #{Dor::Config.assembly.cm_file_name} both exist" if obj.stub_content_metadata_exists? && obj.content_metadata_exists?

          # regular content metadata exists -- do not recreate it
          return LyberCore::Robot::ReturnState.new(status: :skipped, note: "#{Dor::Config.assembly.cm_file_name} exists") if obj.content_metadata_exists?

          # if stub exists, create metadata from the stub, else create basic content metadata
          obj.stub_content_metadata_exists? ? obj.convert_stub_content_metadata : obj.create_basic_content_metadata
          obj.persist_content_metadata
          LyberCore::Robot::ReturnState.COMPLETED
        end
      end
    end # end Assembly module
  end # end DorRepo module
end # end Robots module
