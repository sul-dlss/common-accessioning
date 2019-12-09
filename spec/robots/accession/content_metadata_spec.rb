# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::ContentMetadata do
  subject(:robot) { described_class.new }

  describe '.perform' do
    subject(:perform) { robot.perform(druid) }

    let(:object_client) do
      instance_double(Dor::Services::Client::Object, metadata: metadata_client, find: object)
    end
    let(:metadata_client) do
      instance_double(Dor::Services::Client::Metadata, legacy_update: true)
    end
    let(:druid) { 'druid:ab123cd4567' }
    let(:finder) { instance_double(DruidTools::Druid, find_metadata: 'spec/fixtures/workspace/ab/123/cd/4567/content_metadata.xml') }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(DruidTools::Druid).to receive(:new).and_return(finder)
    end

    context 'on an item' do
      let(:object) do
        Cocina::Models::DRO.new(externalIdentifier: '123',
                                type: Cocina::Models::DRO::TYPES.first,
                                label: 'my repository object',
                                version: 1)
      end

      # rubocop:disable RSpec/ExampleLength
      it 'builds a datastream' do
        perform

        expect(metadata_client).to have_received(:legacy_update).with(
          content: {
            updated: Time,
            content: /<contentMetadata/
          }
        )
      end
      # rubocop:enable RSpec/ExampleLength
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
        expect(object_client).not_to have_received(:metadata)
      end
    end
  end
end
