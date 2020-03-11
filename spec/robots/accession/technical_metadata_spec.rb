# frozen_string_literal: true

require 'spec_helper'

RSpec::Matchers.define_negated_matcher :excluding, :include

RSpec.describe Robots::DorRepo::Accession::TechnicalMetadata do
  subject(:robot) { described_class.new }

  describe '.perform' do
    subject(:perform) { robot.perform(druid) }

    let(:druid) { 'druid:dd116zh0343' }

    let(:object_client) do
      instance_double(Dor::Services::Client::Object, find: object)
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    context 'when a DRO with files' do
      let(:workspace) { File.absolute_path('spec/fixtures/workspace') }
      let(:preserved_file) { "file://#{workspace}/dd/116/zh/0343/dd116zh0343/content/folder1PuSu/story1u.txt" }
      let(:unpreserved_file) { "file://#{workspace}/dd/116/zh/0343/dd116zh0343/content/folder1PuSu/story2r.txt" }

      let(:object) do
        Cocina::Models::DRO.new(externalIdentifier: 'druid:dd116zh0343',
                                type: Cocina::Models::Vocab.object,
                                label: 'my repository object',
                                version: 1,
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
                                          type: Cocina::Models::Vocab.file,
                                          version: 1,
                                          administrative: {
                                            sdrPreserve: true,
                                            shelve: false
                                          }
                                        },
                                        {
                                          externalIdentifier: '222-2',
                                          label: 'folder1PuSu/story2r.txt',
                                          type: Cocina::Models::Vocab.file,
                                          version: 1,
                                          administrative: {
                                            sdrPreserve: false,
                                            shelve: false
                                          }
                                        }
                                      ]
                                    }
                                  }]
                                })
      end

      before do
        #   allow(Dor).to receive(:find).and_return(dor_object)
        # For File URIs, need to use absolute paths
        allow(Settings.sdr).to receive(:local_workspace_root).and_return(workspace)
      end

      context 'when call to techmd service succeeds' do
        before do
          stub_request(:post, 'https://dor-techmd-test.stanford.test/v1/technical-metadata')
            .with(
              body: {
                druid: 'druid:dd116zh0343',
                files: array_including(a_string_matching(preserved_file).and(excluding(unpreserved_file)))
              },
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
              body: {
                druid: 'druid:dd116zh0343',
                files: array_including(a_string_matching(preserved_file).and(excluding(unpreserved_file)))
              },
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

      context 'when file has true for sdrPreserve' do
        before do
          stub_request(:post, 'https://dor-techmd-test.stanford.test/v1/technical-metadata')
            .with(
              body: hash_including(files: array_including(preserved_file)),
              headers: {
                'Content-Type' => 'application/json',
                'Authorization' => 'Bearer rake-generate-token-me'
              }
            )
            .to_return(status: 200, body: '', headers: {})
        end

        it 'file IS sent to techmd service' do
          expect(perform.status).to eq('noop')
        end
      end

      context 'when file has false for sdrPreserve' do
        before do
          stub_request(:post, 'https://dor-techmd-test.stanford.test/v1/technical-metadata')
            .with(
              body: hash_including(
                files: array_including(a_string_matching(preserved_file).and(excluding(unpreserved_file)))
              ),
              headers: {
                'Content-Type' => 'application/json',
                'Authorization' => 'Bearer rake-generate-token-me'
              }
            )
            .to_return(status: 200, body: '', headers: {})
        end

        it 'file is NOT sent to techmd service' do
          expect(perform.status).to eq('noop')
        end
      end
    end

    context 'when the DRO has no files' do
      let(:object) do
        Cocina::Models::DRO.new(externalIdentifier: '123',
                                type: Cocina::Models::Vocab.object,
                                label: 'my repository object',
                                version: 1)
      end

      it 'does not run technical metadata' do
        expect(perform.status).to eq('skipped')
      end
    end

    context 'on a collection' do
      let(:object) do
        Cocina::Models::Collection.new(externalIdentifier: '123',
                                       type: Cocina::Models::Collection::TYPES.first,
                                       label: 'my collection',
                                       version: 1)
      end

      it 'skips' do
        expect(perform.status).to eq('skipped')
      end
    end
  end
end
