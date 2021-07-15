# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Sends initial metadata to PURL, in robots/release/release_publish we push
      # to PURL again with updates to identityMetadata
      class UpdateDoi < Robots::DorRepo::Base
        def initialize
          super('accessionWF', 'update-doi')
        end

        def perform(druid)
          object_client = Dor::Services::Client.object(druid)
          # `#find` returns an instance of a model from the cocina-models gem
          cocina_object = object_client.find

          return LyberCore::Robot::ReturnState.new(status: :skipped, note: 'DOIs are not supported on non-Item objects') unless cocina_object.dro?
          return LyberCore::Robot::ReturnState.new(status: :skipped, note: 'Object does not have a DOI') unless cocina_object.identification&.doi

          # This is an asynchronous result. It will set the publish workflow to complete when it is done.
          object_client.update_doi_metadata
        end
      end
    end
  end
end
