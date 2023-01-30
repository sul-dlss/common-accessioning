# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::Publish do
  let(:druid) { 'druid:zz000zz0001' }
  let(:robot) { described_class.new }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    publish: 'http://dor-services/background-job/123',
                    find: object)
  end
  let(:process) { instance_double(Dor::Workflow::Response::Process, lane_id: 'low') }

  describe '#perform' do
    subject(:perform) { test_perform(robot, druid) }

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
      allow(robot.workflow_service).to receive(:process).and_return(process)
    end

    context 'when called on a Collection' do
      let(:object) { build(:collection, id: druid) }

      it 'publishes metadata' do
        expect(perform.status).to eq 'noop'
        expect(object_client).to have_received(:publish).with(workflow: 'accessionWF', lane_id: 'low')
      end
    end

    context 'when called on an Item' do
      let(:object) { build(:dro, id: druid) }

      it 'publishes metadata' do
        expect(perform.status).to eq 'noop'
        expect(object_client).to have_received(:publish).with(workflow: 'accessionWF', lane_id: 'low')
      end
    end

    context 'when called on an AdminPolicy' do
      let(:object) { build(:admin_policy, id: druid) }

      it 'does not publish metadata' do
        expect(perform.status).to eq 'skipped'
        expect(object_client).not_to have_received(:publish)
      end
    end
  end
end
