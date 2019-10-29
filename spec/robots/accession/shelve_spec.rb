# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::Shelve do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { described_class.new }
  let(:object_client) { instance_double(Dor::Services::Client::Object, shelve: nil, find: object) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    before do
      perform
    end

    context 'when called on a Collection' do
      let(:object) do
        Cocina::Models::Collection.new(externalIdentifier: '123',
                                       type: Cocina::Models::Collection::TYPES.first,
                                       label: 'my collection',
                                       version: 1)
      end

      it 'does not shelve' do
        expect(object_client).not_to have_received(:shelve)
      end
    end

    context 'when called on an Item' do
      let(:object) do
        Cocina::Models::DRO.new(externalIdentifier: '123',
                                type: Cocina::Models::DRO::TYPES.first,
                                label: 'my repository object',
                                version: 1)
      end

      it 'shelves the item' do
        expect(object_client).to have_received(:shelve)
      end
    end

    context 'when called on an APO' do
      let(:object) do
        Cocina::Models::AdminPolicy.new(externalIdentifier: '123',
                                        type: Cocina::Models::AdminPolicy::TYPES.first,
                                        label: 'my admin policy',
                                        version: 1)
      end

      it 'does not shelve' do
        expect(object_client).not_to have_received(:shelve)
      end
    end
  end
end
