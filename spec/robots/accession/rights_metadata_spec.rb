# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::RightsMetadata do
  subject(:perform) { robot.perform(druid) }

  let(:robot) { described_class.new }
  let(:druid) { 'druid:ab123cd4567' }
  let(:apo_id) { 'druid:mx121xx1234' }
  let(:object) do
    Cocina::Models::DRO.new(externalIdentifier: '123',
                            type: Cocina::Models::DRO::TYPES.first,
                            label: 'my repository object',
                            version: 1,
                            administrative: { hasAdminPolicy: apo_id })
  end

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, refresh_metadata: true, metadata: metadata_client, find: object)
  end
  let(:metadata_client) do
    instance_double(Dor::Services::Client::Metadata, legacy_update: true)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  context 'when no rightsMetadata file is found' do
    let(:apo_object_client) { instance_double(Dor::Services::Client::Object, find: apo) }
    let(:apo) do
      Cocina::Models::AdminPolicy.new(externalIdentifier: '123',
                                      type: Cocina::Models::AdminPolicy::TYPES.first,
                                      label: 'my apo object',
                                      version: 1,
                                      administrative: {})
    end
    let(:fedora_obj) { instance_double(Dor::Item, rightsMetadata: datastream) }

    before do
      allow(Dor).to receive(:find).and_return(fedora_obj)
      allow(Dor::Services::Client).to receive(:object).with(apo_id).and_return(apo_object_client)
    end

    context "when rightsMetadata doesn't exist" do
      let(:datastream) { instance_double(Dor::RightsMetadataDS, new?: true) }

      it 'builds a datastream from the remote service call' do
        perform
        expect(metadata_client).to have_received(:legacy_update)
      end
    end

    context 'when rightsMetadata exists' do
      let(:datastream) { instance_double(Dor::RightsMetadataDS, new?: false) }

      it 'does nothing' do
        perform
        expect(metadata_client).not_to have_received(:legacy_update)
      end
    end
  end

  context 'when rightsMetadata file is found' do
    let(:finder) { instance_double(DruidTools::Druid, find_metadata: 'spec/fixtures/ab123cd4567_descMetadata.xml') }

    before do
      allow(DruidTools::Druid).to receive(:new).and_return(finder)
    end

    # rubocop:disable RSpec/ExampleLength
    it 'reads the file in' do
      perform
      expect(metadata_client).to have_received(:legacy_update).with(
        rights: {
          updated: Time,
          content: /first book in Latin/
        }
      )
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
