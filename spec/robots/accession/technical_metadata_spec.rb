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

      context 'when no technicalMetadata.xml file is found' do
        let(:file_group_diff) { instance_double(Moab::FileGroupDifference, file_deltas: { added: [], modified: [] }) }
        let(:inventory_diff) { instance_double(Moab::FileInventoryDifference, group_difference: file_group_diff) }
        let(:technical_metadata_ds) { instance_double(Dor::TechnicalMetadataDS, new?: false, content: dor_technical_metadata) }
        let(:dor_technical_metadata) { double }

        before do
          allow(dor_object).to receive(:technicalMetadata).and_return(technical_metadata_ds)
          allow(Preservation::Client.objects).to receive(:content_inventory_diff).and_return(inventory_diff)
          allow(TechnicalMetadataService).to receive(:add_update_technical_metadata).and_return('tech md')
        end

        context 'when preservation client returns metadata' do
          let(:preservation_technical_metadata) { double }

          before do
            allow(Preservation::Client.objects).to receive(:metadata).and_return(preservation_technical_metadata)
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
            expect(TechnicalMetadataService).to have_received(:add_update_technical_metadata)
              .with(pid: 'druid:bd185gs2259',
                    content_group_diff: file_group_diff,
                    files: [],
                    tech_metadata: dor_technical_metadata,
                    preservation_technical_metadata: preservation_technical_metadata)
          end
          # rubocop:enable RSpec/ExampleLength
        end

        context 'when Preservation::Client gets 404 from API' do
          before do
            allow(Preservation::Client.objects).to receive(:metadata)
              .and_raise(Preservation::Client::NotFoundError)
          end

          # rubocop:disable RSpec/ExampleLength
          it 'runs the technical metadata service and passes nil for the preservation_technical_metadata' do
            perform
            expect(metadata_client).to have_received(:legacy_update).with(
              technical: {
                updated: Time,
                content: /tech md/
              }
            )
            expect(TechnicalMetadataService).to have_received(:add_update_technical_metadata)
              .with(pid: 'druid:bd185gs2259',
                    content_group_diff: file_group_diff,
                    files: [],
                    tech_metadata: dor_technical_metadata,
                    preservation_technical_metadata: nil)
          end
        end
      end

      context 'when technicalMetadata file is found' do
        let(:finder) { instance_double(DruidTools::Druid, find_metadata: 'spec/fixtures/ab123cd4567_descMetadata.xml') }

        before do
          allow(DruidTools::Druid).to receive(:new).and_return(finder)
        end

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
