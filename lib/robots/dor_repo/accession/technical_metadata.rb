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
          # non-items don't generate technical metadata
          return LyberCore::ReturnState.new(status: :skipped, note: 'object is not an item') unless cocina_object.dro?

          # skip if no files
          return LyberCore::ReturnState.new(status: :skipped, note: 'object has no files') if cocina_object.structural.nil? || cocina_object.structural.contains.blank?

          file_uris = PreservedFileUris.new(druid, cocina_object)

          # skip if metadata-only change
          return LyberCore::ReturnState.new(status: :skipped, note: 'change is metadata-only') if metadata_only?(file_uris.filepaths)

          invoke_techmd_service(file_uris)

          LyberCore::ReturnState.new(status: :noop, note: 'Initiated technical metadata generation from technical-metadata-service.')
        end

        private

        def invoke_techmd_service(file_uris)
          files = file_uris.uris.map { |uri_md5| { uri: uri_md5.uri, md5: uri_md5.md5 } }
          req = JSON.generate(druid: druid, files: files, 'lane-id': lane_id, basepath: file_uris.content_dir)
          resp = Faraday.post("#{Settings.tech_md_service.url}/v1/technical-metadata", req,
                              'Content-Type' => 'application/json',
                              'Authorization' => "Bearer #{Settings.tech_md_service.token}")
          raise "Technical-metadata-service returned #{resp.status} when requesting techmd for #{druid}: #{resp.body}" unless resp.status == 200
        end

        def metadata_only?(filepaths)
          # Assume metadata only if no files exist
          filepaths.all? { |filepath| !File.exist?(filepath) }
        end
      end
    end
  end
end
