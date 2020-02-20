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

          file_uris = extract_file_uris(druid, obj)
          invoke_techmd_service(druid, file_uris)

          LyberCore::Robot::ReturnState.new(status: :noop, note: 'Initiated technical metadata generation from technical-metadata-service.')
        end

        private

        def object_for_druid
          Dor::Services::Client.object(druid).find
        end

        def extract_filenames(obj)
          filenames = []
          obj.structural.contains.each do |fileset|
            next if fileset.structural.contains.blank?

            fileset.structural.contains.each do |file|
              filenames << file.label
            end
          end
          filenames
        end

        def extract_file_uris(druid, obj)
          filenames = extract_filenames(obj)

          workspace = DruidTools::Druid.new(druid, File.absolute_path(Settings.sdr.local_workspace_root))
          content_dir = workspace.find_filelist_parent('content', filenames)

          # In future Ruby's, this could be: filenames.map { |filename| URI::File.build(path: File.join(content_dir, filename)).to_s }
          # However, in 2.5.3, URI::File does not exist.
          filenames.map { |filename| "file://#{File.join(content_dir, filename)}" }
        end

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
