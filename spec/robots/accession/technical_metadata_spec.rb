# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::TechnicalMetadata do
  subject(:robot) { described_class.new }

  describe '.perform' do
    subject(:perform) { robot.perform(druid) }

    let(:druid) { 'druid:dd116zh0343' }

    let(:object_client) do
      instance_double(Dor::Services::Client::Object, find: object)
    end

    let(:workflow_client) do
      instance_double(Dor::Workflow::Client, process: process)
    end

    let(:process) do
      instance_double(Dor::Workflow::Response::Process, lane_id: 'low')
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    end

    context 'when a DRO with files' do
      let(:workspace) { File.absolute_path('spec/fixtures/workspace') }

      let(:object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:dd116zh0343',
                                type: Cocina::Models::Vocab.object,
                                label: 'my repository object',
                                version: 1,
                                access: {},
                                administrative: { hasAdminPolicy: 'druid:xx999xx9999' },
                                structural: {
                                  contains: [{
                                    externalIdentifier: '222',
                                    type: Cocina::Models::Vocab.fileset,
                                    label: 'my repository object',
                                    version: 1,
                                    structural: {
                                      contains: [
                                        {
                                          externalIdentifier: '222-1',
                                          label: 'folder1PuSu/story1u.txt',
                                          filename: 'folder1PuSu/story1u.txt',
                                          type: Cocina::Models::Vocab.file,
                                          version: 1,
                                          access: {},
                                          administrative: { publish: true, sdrPreserve: true, shelve: true },
                                          hasMessageDigests: []
                                        }
                                      ]
                                    }
                                  }]
                                })
      end

      before do
        # For File URIs, need to use absolute paths
        allow(Settings.sdr).to receive(:local_workspace_root).and_return(workspace)
      end

      context 'when call to techmd service succeeds' do
        before do
          stub_request(:post, 'https://dor-techmd-test.stanford.test/v1/technical-metadata')
            .with(
              body: "{\"druid\":\"druid:dd116zh0343\",\"files\":[\"file://#{workspace}/dd/116/zh/0343/dd116zh0343/content/folder1PuSu/story1u.txt\"],\"lane-id\":\"low\"}",
              headers: {
                'Content-Type' => 'application/json',
                'Authorization' => 'Bearer rake-generate-token-me'
              }
            )
            .to_return(status: 200, body: '', headers: {})
        end

        it 'invokes techmd service' do
          expect(perform.status).to eq('noop')
        end
      end

      context 'when call to techmd service fails' do
        before do
          stub_request(:post, 'https://dor-techmd-test.stanford.test/v1/technical-metadata')
            .with(
              body: "{\"druid\":\"druid:dd116zh0343\",\"files\":[\"file://#{workspace}/dd/116/zh/0343/dd116zh0343/content/folder1PuSu/story1u.txt\"],\"lane-id\":\"low\"}",
              headers: {
                'Content-Type' => 'application/json',
                'Authorization' => 'Bearer rake-generate-token-me'
              }
            )
            .to_return(status: 500, body: '', headers: {})
        end

        it 'raises' do
          expect { perform }.to raise_error(/Technical-metadata-service returned 500/)
        end
      end

      context 'when the DRO has no files' do
        let(:object) do
          Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                                  type: Cocina::Models::Vocab.object,
                                  label: 'my repository object',
                                  version: 1,
                                  administrative: { hasAdminPolicy: 'druid:xx999xx9999' },
                                  access: {})
        end

        it 'does not run technical metadata' do
          expect(perform.status).to eq('skipped')
        end
      end

      context 'when metadata-only change' do
        let(:workspace) { File.absolute_path('spec/fixtures/workspace2') }

        it 'does not run technical metadata' do
          expect(perform.status).to eq('skipped')
        end
      end
    end

    context 'on a collection' do
      let(:object) do
        Cocina::Models::Collection.new(externalIdentifier: 'druid:bc123df4567',
                                       type: Cocina::Models::Collection::TYPES.first,
                                       label: 'my collection',
                                       access: {},
                                       version: 1)
      end

      it 'skips' do
        expect(perform.status).to eq('skipped')
      end
    end
  end
end
