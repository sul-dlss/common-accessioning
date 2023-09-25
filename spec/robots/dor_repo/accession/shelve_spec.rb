# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::Shelve do
  let(:druid) { 'druid:zz000zz0001' }
  let(:robot) { described_class.new }
  let(:process) do
    instance_double(Dor::Workflow::Response::Process, lane_id: 'low')
  end

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(robot.workflow_service).to receive(:process).and_return(process)
  end

  describe '#perform' do
    subject(:perform) { test_perform(robot, druid) }

    let(:object_client) { instance_double(Dor::Services::Client::Object, find: object, shelve: nil) }

    context 'when called on a non-item' do
      let(:object) { build(:collection) }

      it 'sets the status to skipped' do
        expect(perform.status).to eq 'skipped'
        expect(object_client).not_to have_received(:shelve)
      end
    end

    context 'when called on an Item with files' do
      let(:file_set) do
        { externalIdentifier: 'druid:bc123df4568',
          type: Cocina::Models::FileSetType.file,
          label: 'my repository object',
          version: 1,
          structural: {} }
      end

      let(:object) do
        build(:dro, id: druid).new(
          structural: {
            contains: [file_set]
          }
        )
      end

      it 'shelves the item' do
        expect(perform.status).to eq 'noop'
        expect(object_client).to have_received(:shelve).with(lane_id: 'low')
      end
    end

    context 'when called on an Item without files' do
      let(:object) { build(:dro, id: druid) }

      it 'calls shelve (for the deaccession use case)' do
        expect(perform.status).to eq 'noop'
        expect(object_client).to have_received(:shelve)
      end
    end
  end
end
