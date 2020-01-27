# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::TechnicalMetadata do
  subject(:robot) { described_class.new }

  describe '.perform' do
    subject(:perform) { robot.perform(druid) }

    before do
      allow(Dor).to receive(:find).and_return(object)
    end

    let(:druid) { 'druid:bd185gs2259' }
    let(:builder) { instance_double(DatastreamBuilder, build: true) }

    context 'on an item' do
      let(:object) { Dor::Item.new(pid: druid) }

      let(:object_client) do
        instance_double(Dor::Services::Client::Object, refresh_metadata: true, metadata: metadata_client)
      end
      let(:metadata_client) do
        instance_double(Dor::Services::Client::Metadata, legacy_update: true)
      end

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
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
      let(:object) { Dor::Collection.new(pid: druid) }

      it "doesn't make a datastream" do
        expect(DatastreamBuilder).not_to receive(:new)
        perform
      end
    end
  end
end
