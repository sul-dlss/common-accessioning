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
  let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client, find: object) }
  let(:apo_object_client) { instance_double(Dor::Services::Client::Object, find: apo) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, current: '1') }
  let(:ocr) { instance_double(Dor::TextExtraction::Ocr, possible?: true, required?: false) }
  let(:stt) { instance_double(Dor::TextExtraction::SpeechToText, possible?: true, required?: false) }

  before do
    allow(Dor::TextExtraction::Ocr).to receive(:new).and_return(ocr)
    allow(Dor::TextExtraction::SpeechToText).to receive(:new).and_return(stt)
    allow(LyberCore::WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Dor::Services::Client).to receive(:object).with(apo_druid).and_return(apo_object_client)
  end

  describe '#perform' do
    subject(:perform) { test_perform(robot, druid) }

    context 'when there is no special dissemniation workflow' do
      it 'completes without creating any new workflows' do
        perform
        expect(workflow_client).not_to have_received(:create_workflow_by_name)
      end

      context 'when OCR' do
        let(:ocr) { instance_double(Dor::TextExtraction::Ocr, possible?: possible, required?: required) }

        context 'when is possible but not required' do
          let(:possible) { true }
          let(:required) { false }

          it 'does not start ocrWF' do
            perform
            expect(workflow_client).not_to have_received(:create_workflow_by_name).with(druid, 'ocrWF', version: 2, lane_id: 'default', context:)
          end
        end

        context 'when is required and possible' do
          let(:possible) { true }
          let(:required) { true }

          it 'starts ocrWF' do
            perform
            expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'ocrWF', version: 2, lane_id: 'default', context:)
          end
        end

        context 'when is required and possible and has incoming workflow context' do
          let(:possible) { true }
          let(:required) { true }
          let(:context) { { 'runOCR' => true, 'ocrLanguages' => ['Russian'] } }
          let(:incoming_context) { { 'ocrLanguages' => ['Russian'] } }

          it 'starts ocrWF but removes runOCR from context' do
            perform
            expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'ocrWF', version: 2, lane_id: 'default', context: incoming_context)
          end
        end

        context 'when required but not possible' do
          let(:possible) { false }
          let(:required) { true }

          it 'raises an exception' do
            expect { perform }.to raise_error(RuntimeError, 'Object cannot be OCRd')
          end
        end
      end

      context 'when speech to text' do
        let(:stt) { instance_double(Dor::TextExtraction::SpeechToText, possible?: possible, required?: required) }

        context 'when is possible but not required' do
          let(:possible) { true }
          let(:required) { false }

          it 'does not start speechToTextWF' do
            perform
            expect(workflow_client).not_to have_received(:create_workflow_by_name).with(druid, 'speechToTextWF', version: 2, lane_id: 'default', context:)
          end
        end

        context 'when is required and possible' do
          let(:possible) { true }
          let(:required) { true }

          it 'starts speechToTextWF' do
            perform
            expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'speechToTextWF', version: 2, lane_id: 'default', context:)
          end
        end

        context 'when is required and possible and has incoming workflow context' do
          let(:possible) { true }
          let(:required) { true }
          let(:context) { { 'runSpeechToText' => true, 'ocrLanguages' => ['Russian'] } }
          let(:incoming_context) { { 'ocrLanguages' => ['Russian'] } }

          it 'starts ocrWF but removes runSpeechToText from context' do
            perform
            expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'speechToTextWF', version: 2, lane_id: 'default', context: incoming_context)
          end
        end

        context 'when required but not possible' do
          let(:possible) { false }
          let(:required) { true }

          it 'raises an exception' do
            expect { perform }.to raise_error(RuntimeError, 'Object cannot have speech-to-text applied')
          end
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
      end
    end
  end
end
