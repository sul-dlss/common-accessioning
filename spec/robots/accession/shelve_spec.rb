# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::Shelve do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { described_class.new }
  let(:process) do
    instance_double(Dor::Workflow::Response::Process, lane_id: 'low')
  end

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(robot.workflow_service).to receive(:process).and_return(process)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    let(:object_client) { instance_double(Dor::Services::Client::Object, find: object, shelve: nil) }

    context 'when called on a non-item' do
      let(:object) do
        Cocina::Models::Collection.new(externalIdentifier: 'druid:bc123df4567',
                                       type: Cocina::Models::Vocab.collection,
                                       label: 'my collection',
                                       access: {},
                                       administrative: { hasAdminPolicy: 'druid:xx999xx9999' },
                                       version: 1)
      end

      it 'sets the status to skipped' do
        expect(perform.status).to eq 'skipped'
        expect(object_client).not_to have_received(:shelve)
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
                                administrative: { hasAdminPolicy: 'druid:xx999xx9999' },
                                structural: {
                                  contains: [file_set]
                                })
      end

      it 'shelves the item' do
        expect(perform.status).to eq 'noop'
        expect(object_client).to have_received(:shelve).with(lane_id: 'low')
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
                                access: {},
                                administrative: { hasAdminPolicy: 'druid:xx999xx9999' })
      end

      it 'calls shelve (for the deaccession use case)' do
        expect(perform.status).to eq 'noop'
        expect(object_client).to have_received(:shelve)
      end
    end
  end
end
