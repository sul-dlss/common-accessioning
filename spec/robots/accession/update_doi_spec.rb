# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::UpdateDoi do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { described_class.new }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    update_doi_metadata: true,
                    find: object)
  end
  let(:process) do
    instance_double(Dor::Workflow::Response::Process, lane_id: 'low')
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
      allow(robot.workflow_service).to receive(:process).and_return(process)
    end

    context 'when called on a Collection' do
      let(:object) do
        Cocina::Models::Collection.new(externalIdentifier: 'druid:bc123df4567',
                                       type: Cocina::Models::Collection::TYPES.first,
                                       label: 'my collection',
                                       version: 1,
                                       administrative: { hasAdminPolicy: 'druid:xx999xx9999' },
                                       access: {})
      end

      it 'does not call the API' do
        expect(perform.status).to eq 'skipped'
        expect(object_client).not_to have_received(:update_doi_metadata)
      end
    end

    context 'when called on an Item' do
      context 'with a doi' do
        let(:object) do
          Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                  type: Cocina::Models::DRO::TYPES.first,
                                  label: 'my repository object',
                                  version: 1,
                                  administrative: { hasAdminPolicy: 'druid:xx999xx9999' },
                                  access: {},
                                  identification: { doi: '10.25740/bc123df4567' })
        end

        it 'calls the api' do
          perform
          expect(object_client).to have_received(:update_doi_metadata)
        end
      end

      context 'without a doi' do
        let(:object) do
          Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                  type: Cocina::Models::DRO::TYPES.first,
                                  label: 'my repository object',
                                  version: 1,
                                  administrative: { hasAdminPolicy: 'druid:xx999xx9999' },
                                  access: {})
        end

        it 'calls the api' do
          expect(perform.status).to eq 'skipped'
          expect(object_client).not_to have_received(:update_doi_metadata)
        end
      end
    end

    context 'when called on an APO' do
      let(:object) do
        Cocina::Models::AdminPolicy.new(externalIdentifier: 'druid:bc123df4567',
                                        type: Cocina::Models::AdminPolicy::TYPES.first,
                                        label: 'my admin policy',
                                        version: 1,
                                        administrative: { hasAdminPolicy: 'druid:xx999xx9999' })
      end

      it 'does not call the API' do
        expect(perform.status).to eq 'skipped'
        expect(object_client).not_to have_received(:update_doi_metadata)
      end
    end
  end
end
