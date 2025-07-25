# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::StartAccession do
  subject(:robot) { described_class.new }

  let(:druid) { 'druid:dd116zh0343' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client, find: cocina_object) }
  let(:version_client) do
    instance_double(Dor::Services::Client::ObjectVersion,
                    status: instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: version_open))
  end
  let(:version_open) { false }
  let(:preservation_client) { instance_double(Preservation::Client, objects: preservation_objects_client) }
  let(:preservation_objects_client) { instance_double(Preservation::Client::Objects, checksum: checksums) }
  let(:checksums) { [] }
  let(:purl_fetcher_reader) { instance_double(PurlFetcher::Client::Reader, files_by_digest:) }
  let(:files_by_digest) { [] }
  let(:access) { { view: 'world', download: 'world' } }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Settings.sdr).to receive_messages(local_workspace_root: 'spec/fixtures/workspace', staging_root: 'spec/fixtures/staging')
    allow(Preservation::Client).to receive(:configure).and_return(preservation_client)
    allow(PurlFetcher::Client::Reader).to receive(:new).and_return(purl_fetcher_reader)
  end

  describe '#perform' do
    subject(:perform) { test_perform(robot, druid) }

    context 'when not a DRO and object is not open' do
      let(:cocina_object) { build(:collection, id: druid) }

      it 'does not raise' do
        expect { perform }.not_to raise_error
      end
    end

    context 'when object is still open' do
      let(:cocina_object) { build(:collection, id: druid) }
      let(:version_open) { true }

      it 'raises an error' do
        expect { perform }.to raise_error 'Accessioning has been started with an object that is still open'
      end
    end

    context 'when DRO without files' do
      let(:cocina_object) { build(:dro, id: druid) }

      it 'does not raise' do
        expect { perform }.not_to raise_error
      end
    end

    context 'when DRO with files' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access:, structural:)
      end

      let(:structural) do
        {
          contains: [
            # This file is in workspace.
            {
              externalIdentifier: '222',
              type: Cocina::Models::FileSetType.file,
              label: 'my workspace repository object',
              version: 1,
              structural: {
                contains: [
                  {
                    externalIdentifier: '222-1',
                    label: 'folder1PuSu/story1u.txt',
                    filename: 'folder1PuSu/story1u.txt',
                    type: Cocina::Models::ObjectType.file,
                    version: 1,
                    access: {},
                    size: 7888,
                    administrative: { publish: true, sdrPreserve: true, shelve: false },
                    hasMessageDigests: [{ type: 'md5', digest: '123' }]
                  }
                ]
              }
            },
            # This file is in staging.
            {
              externalIdentifier: '223',
              type: Cocina::Models::FileSetType.file,
              label: 'my staging repository object',
              version: 1,
              structural: {
                contains: [
                  {
                    externalIdentifier: '223-1',
                    label: 'folder1PuSu/story4u.txt',
                    filename: 'folder1PuSu/story4u.txt',
                    type: Cocina::Models::ObjectType.file,
                    version: 1,
                    access: {},
                    size: 7888,
                    administrative: { publish: true, sdrPreserve: true, shelve: false },
                    hasMessageDigests: [{ type: 'md5', digest: '123' }]
                  }
                ]
              }
            },
            # This file is in preservation.
            {
              externalIdentifier: '224',
              type: Cocina::Models::FileSetType.file,
              label: 'my preservation repository object',
              version: 1,
              structural: {
                contains: [
                  {
                    externalIdentifier: '224-1',
                    label: 'folder1PuSu/story5u.txt',
                    filename: 'folder1PuSu/story5u.txt',
                    type: Cocina::Models::ObjectType.file,
                    version: 1,
                    access: {},
                    size: 7888,
                    administrative: { publish: true, sdrPreserve: true, shelve: false },
                    hasMessageDigests: [{ type: 'md5', digest: '123' }]
                  }
                ]
              }
            },
            # This file is on shelves.
            {
              externalIdentifier: '225',
              type: Cocina::Models::FileSetType.file,
              label: 'my shelved repository object',
              version: 1,
              structural: {
                contains: [
                  {
                    externalIdentifier: '225-1',
                    label: 'folder1PuSu/story6u.txt',
                    filename: 'folder1PuSu/story6u.txt',
                    type: Cocina::Models::ObjectType.file,
                    version: 1,
                    access: {},
                    size: 7888,
                    administrative: { publish: true, sdrPreserve: false, shelve: true },
                    hasMessageDigests: [{ type: 'md5', digest: '123' }]
                  }
                ]
              }
            },
            # This file is unshelved and unpreserved. Therefore, it should not be present.
            {
              externalIdentifier: '226',
              type: Cocina::Models::FileSetType.file,
              label: 'my unshelved and unpreserved repository object',
              version: 1,
              structural: {
                contains: [
                  {
                    externalIdentifier: '226-1',
                    label: 'folder1PuSu/story1u.jp2',
                    filename: 'folder1PuSu/story1u.jp2',
                    type: Cocina::Models::ObjectType.file,
                    version: 1,
                    access: {},
                    size: 7888,
                    administrative: { publish: false, sdrPreserve: false, shelve: false },
                    hasMessageDigests: [{ type: 'md5', digest: '123' }]
                  }
                ]
              }
            }
          ],
          hasMemberOrders: [],
          isMemberOf: []
        }
      end

      let(:checksums) do
        [
          { filename: 'folder1PuSu/story1u.txt', md5: '234' },
          { filename: 'folder1PuSu/story5u.txt', md5: '123' }
        ]
      end

      let(:files_by_digest) do
        [
          { '123' => 'folder1PuSu/story6u.txt' },
          { '456' => 'folder1PuSu/story7u.txt' }
        ]
      end

      it 'does not raise' do
        expect { perform }.not_to raise_error
      end
    end

    context 'when DRO with missing file and staging directory not present' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access:, structural:)
      end

      let(:structural) do
        {
          contains: [
            {
              externalIdentifier: '222',
              type: Cocina::Models::FileSetType.file,
              label: 'my missing repository object',
              version: 1,
              structural: {
                contains: [
                  {
                    externalIdentifier: '222-1',
                    label: 'folder1PuSu/story1x.txt',
                    filename: 'folder1PuSu/story1x.txt',
                    type: Cocina::Models::ObjectType.file,
                    version: 1,
                    access: {},
                    size: 7888,
                    administrative: { publish: true, sdrPreserve: true, shelve: true },
                    hasMessageDigests: [{ type: 'md5', digest: '123' }]
                  }
                ]
              }
            }
          ],
          hasMemberOrders: [],
          isMemberOf: []
        }
      end

      it 'raises an error' do
        expect { perform }.to raise_error(RuntimeError, 'Files missing from staging, workspace, shelves, and preservation: folder1PuSu/story1x.txt')
      end
    end

    # rubocop:disable RSpec/SubjectStub
    context 'when DRO with missing file' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access:, structural:)
      end

      let(:structural) do
        {
          contains: [
            {
              externalIdentifier: '222',
              type: Cocina::Models::FileSetType.file,
              label: 'my missing repository object',
              version: 1,
              structural: {
                contains: [
                  {
                    externalIdentifier: '222-1',
                    label: 'folder1PuSu/story1x.txt',
                    filename: 'folder1PuSu/story1x.txt',
                    type: Cocina::Models::ObjectType.file,
                    version: 1,
                    access: {},
                    size: 7888,
                    administrative: { publish: true, sdrPreserve: true, shelve: true },
                    hasMessageDigests: [{ type: 'md5', digest: '123' }]
                  }
                ]
              }
            }
          ],
          hasMemberOrders: [],
          isMemberOf: []
        }
      end

      before do
        allow(Settings.sdr).to receive(:staging_root).and_return('spec/fixtures/xstaging')
        allow(robot).to receive(:sleep)
      end

      it 'retries before raising an error' do
        expect { perform }.to raise_error(RuntimeError, 'Files missing from staging, workspace, shelves, and preservation: folder1PuSu/story1x.txt')
        expect(robot).to have_received(:sleep).exactly(3).times
      end
    end
    # rubocop:enable RSpec/SubjectStub

    context 'when DRO with shelved file but object is not on shelves' do
      let(:cocina_object) do
        build(:dro, id: druid).new(access:, structural:)
      end

      let(:structural) do
        {
          contains: [
            # This file is on shelves.
            {
              externalIdentifier: '225',
              type: Cocina::Models::FileSetType.file,
              label: 'my shelved repository object',
              version: 1,
              structural: {
                contains: [
                  {
                    externalIdentifier: '225-1',
                    label: 'folder1PuSu/story6u.txt',
                    filename: 'folder1PuSu/story6u.txt',
                    type: Cocina::Models::ObjectType.file,
                    version: 1,
                    access: {},
                    size: 7888,
                    administrative: { publish: true, sdrPreserve: false, shelve: true },
                    hasMessageDigests: [{ type: 'md5', digest: '123' }]
                  }
                ]
              }
            }
          ],
          hasMemberOrders: [],
          isMemberOf: []
        }
      end

      before do
        allow(purl_fetcher_reader).to receive(:files_by_digest).and_raise(PurlFetcher::Client::NotFoundResponseError)
      end

      it 'raises an error' do
        expect { perform }.to raise_error(RuntimeError, 'Files missing from staging, workspace, shelves, and preservation: folder1PuSu/story6u.txt')
      end
    end
  end
end
