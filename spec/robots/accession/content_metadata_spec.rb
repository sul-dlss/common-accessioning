# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::ContentMetadata do
  subject(:robot) { described_class.new }

  describe '.perform' do
    subject(:perform) { robot.perform(druid) }

    let(:object_client) do
      instance_double(Dor::Services::Client::Object, update: nil, find: object)
    end

    let(:druid) { 'druid:ab123cd4567' }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    context 'when an item' do
      let(:object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::DRO::TYPES.first,
                                label: 'my repository object',
                                access: {},
                                administrative: { hasAdminPolicy: 'druid:xx999xx9999' },
                                version: 1)
      end

      context 'when no contentMetadata file is found' do
        it 'builds a datastream from the remote service call' do
          expect(perform.status).to eq 'skipped'
          expect(object_client).not_to have_received(:update)
        end
      end

      context 'when contentMetadata file is found' do
        let(:finder) { instance_double(DruidTools::Druid, find_metadata: 'spec/fixtures/workspace/ab/123/cd/4567/content_metadata.xml') }

        before do
          allow(DruidTools::Druid).to receive(:new).and_return(finder)
        end

        it 'builds a datastream' do
          perform

          expect(object_client).to have_received(:update).with(params: Cocina::Models::DRO)
        end
      end
    end

    context 'when a collection' do
      let(:object) do
        Cocina::Models::Collection.new(externalIdentifier: 'druid:bc123df4567',
                                       type: Cocina::Models::Collection::TYPES.first,
                                       label: 'my collection',
                                       version: 1,
                                       access: {})
      end

      it "doesn't make a datastream" do
        perform
        expect(object_client).not_to have_received(:update)
      end
    end
  end
end
