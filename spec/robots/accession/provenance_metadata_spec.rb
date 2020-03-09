# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::ProvenanceMetadata do
  let(:robot) { described_class.new }
  let(:druid) { 'druid:aa123bb4567' }

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    let(:object_client) do
      instance_double(Dor::Services::Client::Object, metadata: metadata_client)
    end
    let(:metadata_client) do
      instance_double(Dor::Services::Client::Metadata, legacy_update: true)
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(robot).to receive(:create_workflow_provenance).and_return('<provenance/>')
    end

    it 'generates provenance' do
      perform
      expect(metadata_client).to have_received(:legacy_update).with(
        provenance: {
          updated: Time,
          content: '<provenance/>'
        }
      )
    end
  end

  describe '#create_workflow_provenance' do
    subject(:build) { robot.send(:create_workflow_provenance, druid, time: '2020-01-28T11:24:26-06:00') }

    it 'make the xml' do
      expect(build).to be_equivalent_to '<?xml version="1.0"?>
       <provenanceMetadata objectId="druid:aa123bb4567">
         <agent name="DOR">
           <what object="druid:aa123bb4567">
             <event who="DOR-accessionWF" when="2020-01-28T11:24:26-06:00">DOR Common Accessioning completed</event>
           </what>
         </agent>
       </provenanceMetadata>'
    end
  end
end
