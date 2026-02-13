# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates the technical metadata by calling technical-metadata-service
      class TechnicalMetadata < LyberCore::Robot
        def initialize
          super('accessionWF', 'technical-metadata')
        end

        def perform_work
          return LyberCore::ReturnState.new(status: :skipped, note: 'object is not an item') unless cocina_object.dro?

          # This is the list of files that are marked for preservation, but still in the dor workspace
          file_uris = PreservedFileUris.new(druid, cocina_object)

          return LyberCore::ReturnState.new(status: :skipped, note: 'object has no preserved files') if file_uris.filepaths.empty?

          invoke_techmd_service(file_uris)

          # The TechnicalMetadataWorkflowJob in sul-dlss/technical-metadata will complete this workflow step.
          LyberCore::ReturnState.new(status: :noop, note: 'Initiated technical metadata generation from technical-metadata-service.')
        end

        private

        def invoke_techmd_service(file_uris)
          files = file_uris.uris.map { |uri_md5| { uri: uri_md5.uri, md5: uri_md5.md5 } }
          req = JSON.generate(druid:, files:, 'lane-id': lane_id, basepath: file_uris.content_dir)
          resp = Faraday.post("#{Settings.tech_md_service.url}/v1/technical-metadata", req,
                              'Content-Type' => 'application/json',
                              'Authorization' => "Bearer #{Settings.tech_md_service.token}")
          raise "Technical-metadata-service returned #{resp.status} when requesting techmd for #{druid}: #{resp.body}" unless resp.status == 200
        end
      end
    end
  end
end
