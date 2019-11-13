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

    context 'when called on a non-item' do
      let(:object) do
        Cocina::Models::Collection.new(externalIdentifier: '123',
                                       type: Cocina::Models::Collection::TYPES.first,
                                       label: 'my collection',
                                       version: 1)
      end

      before do
        allow(robot.workflow_service).to receive(:update_status)
        allow(object_client).to receive(:shelve).and_raise(Dor::Services::Client::UnexpectedResponse)
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
                note: 'Non-item, nothing to do')
      end
    end

    context 'when called on an Item' do
      let(:object) do
        Cocina::Models::DRO.new(externalIdentifier: '123',
                                type: Cocina::Models::DRO::TYPES.first,
                                label: 'my repository object',
                                version: 1)
      end

      context "when it's successful" do
        it 'shelves the item' do
          perform
          expect(object_client).to have_received(:shelve)
        end
      end
    end
  end
end
