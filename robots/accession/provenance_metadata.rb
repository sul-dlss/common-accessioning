# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession

      class ProvenanceMetadata < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'provenance-metadata')
        end

        def perform(druid)
          obj = Dor.find(druid)
          build_datastream(obj, 'accessionWF', 'DOR Common Accessioning completed')
        end

        private

        def build_datastream(obj, workflow_id, event_text)
          workflow_provenance = create_workflow_provenance(obj.pid, workflow_id, event_text)
          ds = obj.provenanceMetadata
          ds.label ||= 'Provenance Metadata'
          ds.ng_xml = workflow_provenance
          ds.save
        end

        # @return [Nokogiri::Document]
        def create_workflow_provenance(druid, workflow_id, event_text)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.provenanceMetadata(objectId: druid) do
              xml.agent(name: 'DOR') do
                xml.what(object: druid) do
                  xml.event(who: "DOR-#{workflow_id}", when: Time.new.iso8601) do
                    xml.text(event_text)
                  end
                end
              end
            end
          end
          builder.doc
        end
      end
    end
  end
end
