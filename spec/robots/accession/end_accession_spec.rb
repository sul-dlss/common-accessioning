# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::EndAccession do
  subject(:robot) { described_class.new }

  let(:object) do
    Cocina::Models::DRO.new(externalIdentifier: '123',
                            type: Cocina::Models::DRO::TYPES.first,
                            label: 'my repository object',
                            version: 1,
                            administrative: { hasAdminPolicy: apo_id })
  end
  let(:apo) do
    Cocina::Models::AdminPolicy.new(externalIdentifier: '123',
                                    type: Cocina::Models::AdminPolicy::TYPES.first,
                                    label: 'my apo object',
                                    version: 1,
                                    administrative: {})
  end

  let(:druid) { 'druid:oo000oo0001' }
  let(:apo_id) { 'druid:mx121xx1234' }
  let(:process) { instance_double(Dor::Workflow::Response::Process, lane_id: 'default') }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil, process: process) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client, find: object, workspace: workspace_client) }
  let(:apo_object_client) { instance_double(Dor::Services::Client::Object, find: apo) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, current: '1') }
  let(:workspace_client) { instance_double(Dor::Services::Client::Workspace, cleanup: true) }

  before do
    allow(Dor).to receive(:find).with(druid).and_return(object)
    allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Dor::Services::Client).to receive(:object).with(apo_id).and_return(apo_object_client)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    context 'when there is no special dissemniation workflow' do
      it 'cleans up' do
        perform
        expect(workspace_client).to have_received(:cleanup)
      end
    end

    context 'when there is a special dissemniation workflow' do
      let(:apo) do
        Cocina::Models::AdminPolicy.new(externalIdentifier: '123',
                                        type: Cocina::Models::AdminPolicy::TYPES.first,
                                        label: 'my apo object',
                                        version: 1,
                                        administrative: { registration_workflow: 'wasDisseminationWF' })
      end

      it 'kicks off that workflow' do
        perform
        expect(workflow_client).to have_received(:create_workflow_by_name)
          .with(druid, 'wasDisseminationWF', version: '1', lane_id: 'default')
        expect(workspace_client).to have_received(:cleanup)
      end
    end
  end
end
