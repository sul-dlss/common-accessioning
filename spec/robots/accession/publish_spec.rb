# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::Publish do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { described_class.new }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    publish: 'http://dor-services/background-job/123',
                    find: object)
  end
  let(:process) do
    instance_double(Dor::Workflow::Response::Process, lane_id: 'low')
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
      allow(robot.workflow_service).to receive(:update_status)
      allow(robot.workflow_service).to receive(:process).and_return(process)
      perform
    end

    context 'when called on a Collection' do
      let(:object) do
        Cocina::Models::Collection.new(externalIdentifier: 'druid:bc123df4567',
                                       type: Cocina::Models::Collection::TYPES.first,
                                       label: 'my collection',
                                       version: 1,
                                       access: {})
      end

      it 'publishes metadata' do
        expect(object_client).to have_received(:publish).with(workflow: 'accessionWF', lane_id: 'low')
      end
    end

    context 'when called on an Item' do
      let(:object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                type: Cocina::Models::DRO::TYPES.first,
                                label: 'my repository object',
                                version: 1,
                                access: {})
      end

      it 'publishes metadata' do
        expect(object_client).to have_received(:publish).with(workflow: 'accessionWF', lane_id: 'low')
      end
    end

    context 'when called on an APO' do
      let(:object) do
        Cocina::Models::AdminPolicy.new(externalIdentifier: 'druid:bc123df4567',
                                        type: Cocina::Models::AdminPolicy::TYPES.first,
                                        label: 'my admin policy',
                                        version: 1,
                                        administrative: {})
      end

      it 'does not publish metadata' do
        expect(object_client).not_to have_received(:publish)
      end

      it 'sets publish-complete to completed' do
        expect(robot.workflow_service).to have_received(:update_status).with(druid: druid, workflow: 'accessionWF', process: 'publish-complete', status: 'completed', elapsed: 1, note: 'APOs are not published, so marking completed.')
      end
    end
  end
end
