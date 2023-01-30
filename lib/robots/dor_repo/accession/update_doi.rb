# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Sends initial metadata to PURL, in robots/release/release_publish we push
      # to PURL again with updates to identityMetadata
      class UpdateDoi < LyberCore::Robot
        def initialize
          super('accessionWF', 'update-doi')
        end

        def perform_work
          return LyberCore::ReturnState.new(status: :skipped, note: 'DOIs are not supported on non-Item objects') unless cocina_object.dro?
          return LyberCore::ReturnState.new(status: :skipped, note: 'Object does not have a DOI') unless cocina_object.identification&.doi
          return LyberCore::ReturnState.new(status: :skipped, note: 'Object belongs to the SDR graveyard APO') if cocina_object.administrative.hasAdminPolicy == Settings.graveyard_admin_policy.druid

          # This is an asynchronous result. It will set the publish workflow to complete when it is done.
          object_client.update_doi_metadata
        end
      end
    end
  end
end
