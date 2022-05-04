# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates or updates the descMetadata datastream
      # it looks for a file on disk that is newer than the datastream.
      class DescriptiveMetadata < Robots::DorRepo::Base
        def initialize
          super('accessionWF', 'descriptive-metadata')
        end

        def perform(druid)
          object = DruidTools::Druid.new(druid, Settings.stacks.local_workspace_root)
          path = object.find_metadata('descMetadata.xml')
          return LyberCore::Robot::ReturnState.new(status: :skipped, note: 'No descMetadata.xml was provided') unless path

          object_client = Dor::Services::Client.object(druid)
          cocina_object = object_client.find
          mods_ng = Nokogiri::XML(File.read(path))
          description_props = Cocina::Models::Mapping::FromMods::Description.props(mods: mods_ng, druid: cocina_object.externalIdentifier,
                                                                                   label: cocina_object.label)
          object_client.update(params: cocina_object.new(description: description_props))
        end
      end
    end
  end
end
