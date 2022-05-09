# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates structural metadata based on contentMetadata.xml
      class ContentMetadata < Robots::DorRepo::Base
        def initialize
          super('accessionWF', 'content-metadata')
        end

        def perform(druid)
          object_client = Dor::Services::Client.object(druid)

          # `#find` returns an instance of a model from the cocina-models gem
          #
          # Objects that aren't items/DROs do not have content metadata attached
          cocina_object = object_client.find
          return unless cocina_object.dro?

          object = DruidTools::Druid.new(druid, Settings.stacks.local_workspace_root)
          path = object.find_metadata('contentMetadata.xml')

          return LyberCore::Robot::ReturnState.new(status: :skipped, note: 'No contentMetadata.xml was provided') unless path

          updated = cocina_object.new(structural: Dor::StructuralMetadata.update(File.read(path), cocina_object))
          object_client.update(params: updated)
        end
      end
    end
  end
end
