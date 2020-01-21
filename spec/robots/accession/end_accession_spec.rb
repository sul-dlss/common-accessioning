# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::EndAccession do
  subject(:robot) { described_class.new }

  let(:object) { instance_double(Dor::Item, admin_policy_object: apo) }
  let(:apo) { Dor::AdminPolicyObject.new }
  let(:druid) { 'druid:oo000oo0001' }
  let(:process) { instance_double(Dor::Workflow::Response::Process, lane_id: 'default') }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil, process: process) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, current: '1') }

  before do
    allow(Dor).to receive(:find).with(druid).and_return(object)
    allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    context 'when there is no special dissemniation workflow' do
      it 'kicks off dissemination' do
        perform
        expect(workflow_client).to have_received(:create_workflow_by_name)
          .with(druid, 'disseminationWF', version: '1', lane_id: 'default')
      end
    end

    context 'when there is a special dissemniation workflow' do
      before do
        apo.administrativeMetadata.content = xml
      end

      let(:xml) do
        <<~XML
          <administrativeMetadata>
            <dissemination>
              <workflow id="wasDisseminationWF"/>
            </dissemination>
          </administrativeMetadata>
        XML
      end

      it 'kicks off both dissemination workflows' do
        perform
        expect(workflow_client).to have_received(:create_workflow_by_name)
          .with(druid, 'wasDisseminationWF', version: '1', lane_id: 'default')
        expect(workflow_client).to have_received(:create_workflow_by_name)
          .with(druid, 'disseminationWF', version: '1', lane_id: 'default')
      end
    end
  end
end
