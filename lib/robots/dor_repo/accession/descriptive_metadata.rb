# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates or updates the descriptive metadata
      # it looks for descMetadata.xml file on disk; if found uses it to update the object.
      class DescriptiveMetadata < LyberCore::Robot
        def initialize
          super('accessionWF', 'descriptive-metadata')
        end

        def perform_work
          path = druid_object.find_metadata('descMetadata.xml')
          return LyberCore::ReturnState.new(status: :skipped, note: 'No descMetadata.xml was provided') unless path

          mods_ng = Nokogiri::XML(File.read(path))
          description_props = Cocina::Models::Mapping::FromMods::Description.props(mods: mods_ng, druid: cocina_object.externalIdentifier,
                                                                                   label: cocina_object.label)
          object_client.update(params: cocina_object.new(description: description_props))
        end
      end
    end
  end
end
