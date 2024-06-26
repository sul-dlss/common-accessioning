# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::EndAccession do
  subject(:robot) { described_class.new }

  let(:object) { build(:dro, id: druid, admin_policy_id: apo_druid) }
  let(:apo) { build(:admin_policy, id: apo_druid) }
  let(:druid) { 'druid:zz000zz0001' }
  let(:apo_druid) { 'druid:mx121xx1234' }
  let(:context) { {} }
  let(:process) { instance_double(Dor::Workflow::Response::Process, lane_id: 'default', context:) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil, process:) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client, find: object, workspace: workspace_client) }
  let(:apo_object_client) { instance_double(Dor::Services::Client::Object, find: apo) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, current: '1') }
  let(:workspace_client) { instance_double(Dor::Services::Client::Workspace, cleanup: true) }
  let(:ocr) { instance_double(Dor::TextExtraction::Ocr, possible?: true, required?: false) }

  before do
    allow(Dor::TextExtraction::Ocr).to receive(:new).and_return(ocr)
    allow(LyberCore::WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Dor::Services::Client).to receive(:object).with(apo_druid).and_return(apo_object_client)
  end

  describe '#perform' do
    subject(:perform) { test_perform(robot, druid) }

    let(:return_status) { perform.status }

    context 'when there is no special dissemniation workflow' do
      it 'cleans up' do
        expect(return_status).to eq 'noop'
        expect(workspace_client).to have_received(:cleanup).with(workflow: 'accessionWF', lane_id: 'default')
      end

      context 'when OCR is possible but not required' do
        let(:ocr) { instance_double(Dor::TextExtraction::Ocr, possible?: true, required?: false) }

        it 'does not start ocrWF' do
          perform
          expect(workflow_client).not_to have_received(:create_workflow_by_name).with(druid, 'ocrWF', version: 2, lane_id: 'default')
        end
      end

      context 'when OCR is required and possible' do
        let(:ocr) { instance_double(Dor::TextExtraction::Ocr, possible?: true, required?: true) }

        it 'starts ocrWF' do
          perform
          expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'ocrWF', version: 2, lane_id: 'default')
        end
      end

      context 'when OCR is required but not possible' do
        let(:ocr) { instance_double(Dor::TextExtraction::Ocr, possible?: false, required?: true) }

        it 'raises an exception' do
          expect { perform }.to raise_error(RuntimeError, 'Object cannot be OCRd')
        end
      end
    end

    context 'when there is a special dissemniation workflow' do
      let(:apo) do
        build(:admin_policy, id: apo_druid).new(
          administrative: {
            disseminationWorkflow: 'wasDisseminationWF',
            hasAdminPolicy: 'druid:xx999xx9999',
            hasAgreement: 'druid:bb033gt0615',
            accessTemplate: { view: 'world', download: 'world' }
          }
        )
      end

      it 'kicks off that workflow' do
        perform
        expect(workflow_client).to have_received(:create_workflow_by_name)
          .with(druid, 'wasDisseminationWF', version: '1', lane_id: 'default')
        expect(workspace_client).to have_received(:cleanup).with(workflow: 'accessionWF', lane_id: 'default')
      end
    end
  end
end
