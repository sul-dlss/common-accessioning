# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      class ContentMetadataCreate < Robots::DorRepo::Assembly::Base
        def initialize(opts = {})
          super('assemblyWF', 'content-metadata-create', opts)
        end

        # generate the content metadata for this object based on some logic of whether
        # stub or regular content metadata already exists
        def perform(druid)
          obj =  item(druid)
          return LyberCore::Robot::ReturnState.new(status: :skipped, note: 'object is not an item') unless obj.item? # not an item, skip

          # both stub and regular content metadata exist -- this is an ambiguous situation and generates an error
          raise "#{Settings.assembly.stub_cm_file_name} and #{Settings.assembly.cm_file_name} both exist for #{druid}" if obj.stub_content_metadata_exists? && obj.content_metadata_exists?

          # regular content metadata exists -- do not recreate it
          return LyberCore::Robot::ReturnState.new(status: :skipped, note: "#{Settings.assembly.cm_file_name} exists") if obj.content_metadata_exists?

          # neither stubContentMetadata or contentMetadata exist.
          raise "Unable to find #{Settings.assembly.stub_cm_file_name} or #{Settings.assembly.cm_file_name}" unless obj.stub_content_metadata_exists?

          obj.convert_stub_content_metadata
          obj.persist_content_metadata
          LyberCore::Robot::ReturnState.new(status: 'completed')
        end
      end
    end
  end
end
