# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Creates the technicalMetadata datastream
      class TechnicalMetadata < Robots::DorRepo::Base
        def initialize
          super('accessionWF', 'technical-metadata')
        end

        def perform(druid)
          obj = Dor::Services::Client.object(druid).find

          # non-items don't generate contentMetadata
          return LyberCore::Robot::ReturnState.new(status: :skipped, note: 'object is not an item') unless obj.dro?

          # skip if no files
          return LyberCore::Robot::ReturnState.new(status: :skipped, note: 'object has no files') if obj.structural.contains.blank?

          file_uris = FileUris.build(druid, obj)
          invoke_techmd_service(druid, file_uris)

          LyberCore::Robot::ReturnState.new(status: :noop, note: 'Initiated technical metadata generation from technical-metadata-service.')
        end

        private

        def invoke_techmd_service(druid, file_uris)
          req = JSON.generate(druid: druid, files: file_uris)
          resp = Faraday.post("#{Settings.tech_md_service.url}/v1/technical-metadata", req,
                              'Content-Type' => 'application/json',
                              'Authorization' => "Bearer #{Settings.tech_md_service.token}")
          raise "Technical-metadata-service returned #{resp.status} when requesting techmd for #{druid}: #{resp.body}" unless resp.status == 200
        end
      end
    end
  end
end
