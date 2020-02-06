# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      class ProvenanceMetadata < Robots::DorRepo::Base
        def initialize
          super('accessionWF', 'provenance-metadata')
        end

        def perform(druid)
          workflow_provenance = create_workflow_provenance(druid)
          object_client = Dor::Services::Client.object(druid)
          object_client.metadata.legacy_update(
            provenance: {
              updated: Time.now,
              content: workflow_provenance
            }
          )
        end

        private

        # @return [String]
        def create_workflow_provenance(druid, time: Time.new.iso8601)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.provenanceMetadata(objectId: druid) do
              xml.agent(name: 'DOR') do
                xml.what(object: druid) do
                  xml.event(who: 'DOR-accessionWF', when: time) do
                    xml.text('DOR Common Accessioning completed')
                  end
                end
              end
            end
          end
          builder.doc.to_s
        end
      end
    end
  end
end
