# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Requests that Orcid works be created / updated for the object
      class UpdateOrcidWork < LyberCore::Robot
        def initialize
          super('accessionWF', 'update-orcid-work')
        end

        def perform_work
          return LyberCore::ReturnState.new(status: :skipped, note: 'Orcid works are not supported on non-Item objects') unless cocina_object.dro?
          return LyberCore::ReturnState.new(status: :skipped, note: 'Object does not cited contributors with Orcid ids') unless has_orcid_ids?
          return LyberCore::ReturnState.new(status: :skipped, note: 'Object belongs to the SDR graveyard APO') if cocina_object.administrative.hasAdminPolicy == Settings.graveyard_admin_policy.druid

          # This is an asynchronous operation.
          object_client.update_orcid_work
        end

        private

        def has_orcid_ids?
          SulOrcidClient::CocinaSupport.cited_orcidids(cocina_object.description).any?
        end
      end
    end
  end
end
