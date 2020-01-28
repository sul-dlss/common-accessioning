# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::TechnicalMetadata do
  subject(:robot) { described_class.new }

  describe '.perform' do
    subject(:perform) { robot.perform(druid) }

    let(:druid) { 'druid:bd185gs2259' }

    let(:object_client) do
      instance_double(Dor::Services::Client::Object, find: object, metadata: metadata_client)
    end
    let(:metadata_client) do
      instance_double(Dor::Services::Client::Metadata, legacy_update: true)
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    context 'on an item' do
      let(:dor_object) { Dor::Item.new(pid: druid) }

      let(:object) do
        Cocina::Models::DRO.new(externalIdentifier: '123',
                                type: Cocina::Models::DRO::TYPES.first,
                                label: 'my repository object',
                                version: 1)
      end

      before do
        allow(Dor).to receive(:find).and_return(dor_object)
      end

      context 'when no technicalMetadata file is found' do
        before do
          allow(TechnicalMetadataService).to receive(:add_update_technical_metadata).and_return('tech md')
        end

        # rubocop:disable RSpec/ExampleLength
        it 'creates new metadata' do
          perform
          expect(metadata_client).to have_received(:legacy_update).with(
            technical: {
              updated: Time,
              content: /tech md/
            }
          )
        end
        # rubocop:enable RSpec/ExampleLength
      end

      context 'when technicalMetadata file is found' do
        let(:finder) { instance_double(DruidTools::Druid, find_metadata: 'spec/fixtures/ab123cd4567_descMetadata.xml') }

        before do
          allow(DruidTools::Druid).to receive(:new).and_return(finder)
        end

        # rubocop:disable RSpec/ExampleLength
        it 'creates new metadata' do
          perform
          expect(metadata_client).to have_received(:legacy_update).with(
            technical: {
              updated: Time,
              content: /first book in Latin/
            }
          )
        end
        # rubocop:enable RSpec/ExampleLength
      end
    end

    context 'on a collection' do
      let(:object) do
        Cocina::Models::Collection.new(externalIdentifier: '123',
                                       type: Cocina::Models::Collection::TYPES.first,
                                       label: 'my collection',
                                       version: 1)
      end

      it "doesn't make a datastream" do
        perform
        expect(metadata_client).not_to have_received(:legacy_update)
      end
    end
  end
end
