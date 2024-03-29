# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::UpdateOrcidWork do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { described_class.new }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    update_orcid_work: true,
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
      let(:object) { build(:collection) }

      it 'does not call the API' do
        expect(perform.status).to eq 'skipped'
        expect(object_client).not_to have_received(:update_orcid_work)
      end
    end

    context 'when called on an Item' do
      context 'with a doi' do
        let(:object) do
          build(:dro)
        end

        it 'calls the api' do
          perform
          expect(object_client).to have_received(:update_orcid_work)
        end

        context 'when in the graveyard APO' do
          let(:object) do
            build(:dro).new(
              administrative: {
                hasAdminPolicy: Settings.graveyard_admin_policy.druid
              }
            )
          end

          it 'does not call the API' do
            expect(perform.status).to eq('skipped')
            expect(perform.note).to eq('Object belongs to the SDR graveyard APO')
            expect(object_client).not_to have_received(:update_orcid_work)
          end
        end
      end
    end

    context 'when called on an APO' do
      let(:object) { build(:admin_policy) }

      it 'does not call the API' do
        expect(perform.status).to eq 'skipped'
        expect(object_client).not_to have_received(:update_orcid_work)
      end
    end
  end
end
