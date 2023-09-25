# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::DescriptiveMetadata do
  subject(:robot) { described_class.new }

  describe '#perform' do
    subject(:perform) { test_perform(robot, druid) }

    let(:druid) { 'druid:bb123cd4567' }
    let(:cocina_object) { build(:dro, id: druid) }

    let(:object_client) do
      instance_double(Dor::Services::Client::Object, update: nil, find: cocina_object)
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    context 'when no descMetadata.xml file is found' do
      it 'does nothing and returns status skipped' do
        expect(perform.status).to eq 'skipped'
        expect(object_client).not_to have_received(:find)
      end
    end

    context 'when descMetadata.xml file is found' do
      let(:finder) { instance_double(DruidTools::Druid, find_metadata: 'spec/fixtures/bb123cd4567_descMetadata.xml') }

      let(:expected_cocina_object) do
        cocina_object.new(description: {
                            title: [
                              {
                                structuredValue: [
                                  { value: 'A', type: 'nonsorting characters' },
                                  { value: 'first book in Latin', type: 'main title' }
                                ],
                                note: [
                                  { value: '2', type: 'nonsorting character count' }
                                ]
                              }
                            ],
                            purl: 'https://purl-example.stanford.edu/bb123cd4567'
                          })
      end

      before do
        allow(DruidTools::Druid).to receive(:new).and_return(finder)
      end

      it 'reads the file in' do
        perform
        expect(object_client).to have_received(:update).with(params: expected_cocina_object)
      end
    end
  end
end
