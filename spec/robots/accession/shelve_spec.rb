# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::Shelve do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { described_class.new }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    let(:object_client) { instance_double(Dor::Services::Client::Object, find: object, shelve: nil) }

    before do
      allow(robot.workflow_service).to receive(:update_status)
    end

    context 'when called on a non-item' do
      let(:object) do
        Cocina::Models::Collection.new(externalIdentifier: 'druid:bc123df4567',
                                       type: Cocina::Models::Vocab.collection,
                                       label: 'my collection',
                                       access: {},
                                       version: 1)
      end

      it 'sets the shelve-complete step to completed' do
        perform
        expect(object_client).not_to have_received(:shelve)
        expect(robot.workflow_service).to have_received(:update_status)
          .with(druid: druid,
                workflow: 'accessionWF',
                process: 'shelve-complete',
                status: 'completed',
                elapsed: 1,
                note: 'Not an item/DRO, nothing to do')
      end
    end

    context 'when called on an Item with files' do
      let(:file_set) do
        { externalIdentifier: 'druid:bc123df4568',
          type: Cocina::Models::Vocab.fileset,
          label: 'my repository object',
          version: 1 }
      end

      let(:object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'my repository object',
                                version: 1,
                                access: {},
                                structural: {
                                  contains: [file_set]
                                })
      end

      it 'shelves the item' do
        perform
        expect(object_client).to have_received(:shelve)
      end
    end

    context 'when called on an Item without files' do
      let(:object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::Vocab.object,
                                label: 'my repository object',
                                version: 1,
                                structural: {
                                  contains: []
                                },
                                access: {})
      end

      it 'does not shelve the item' do
        perform
        expect(object_client).not_to have_received(:shelve)
        expect(robot.workflow_service).to have_received(:update_status)
          .with(druid: druid,
                workflow: 'accessionWF',
                process: 'shelve-complete',
                status: 'completed',
                elapsed: 1,
                note: 'object has no files')
      end
    end
  end
end
