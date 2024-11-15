# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::ChecksumCompute do
  let(:robot) { described_class.new }
  let(:bare_druid) { 'bb222cc3333' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_object, update: true)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  describe '#perform' do
    subject(:perform) { test_perform(robot, druid) }

    let(:cocina_object) { build(:dro, id: druid) }

    context 'when the item is a DRO' do
      let(:assembly_item) { Dor::Assembly::Item.new(druid: bare_druid) }

      before do
        allow(robot).to receive(:assembly_item).and_return(assembly_item)
        allow(robot).to receive(:compute_checksums).with(assembly_item, cocina_object).and_return([])
      end

      it 'computes checksums' do
        perform
        expect(object_client).to have_received(:update)
      end
    end

    context 'when not a DRO' do
      let(:cocina_object) { build(:collection, id: druid) }

      it 'does not compute checksums' do
        expect(robot).not_to receive(:compute_checksums)
        perform
      end
    end
  end

  describe '#compute_checksums' do
    let(:cocina_object) { build(:dro, id: druid).new(structural:) }

    let(:structural) do
      { contains: [{ type: Cocina::Models::FileSetType.image,
                     externalIdentifier: 'bb222cc3333_1',
                     label: 'Image 1',
                     version: 1,
                     structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                externalIdentifier: 'https://cocina.sul.stanford.edu/file/331681a1-a796-4940-a42b-ee47211e5264',
                                                label: 'image111.tif',
                                                filename: 'image111.tif',
                                                size: 0,
                                                version: 1,
                                                hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                administrative: { publish: false, sdrPreserve: true, shelve: false } }] } },
                   { type: Cocina::Models::FileSetType.image,
                     externalIdentifier: 'bb222cc3333_2',
                     label: 'Image 2',
                     version: 1,
                     structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                externalIdentifier: 'https://cocina.sul.stanford.edu/file/ced39e5f-ff5d-4b76-b688-22369e410f3b',
                                                label: 'image112.tif',
                                                filename: 'image112.tif',
                                                size: 0,
                                                version: 1,
                                                hasMessageDigests: [{ type: 'sha1', digest: '5c9f6dc2ca4fd3329619b54a2c6f99a08c088444' },
                                                                    { type: 'md5', digest: 'ac440802bd590ce0899dafecc5a5ab1b' }],
                                                access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                administrative: { publish: false, sdrPreserve: true, shelve: false } }] } },
                   { type: Cocina::Models::FileSetType.image,
                     externalIdentifier: 'bb222cc3333_3',
                     label: 'Image 3',
                     version: 1,
                     structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                externalIdentifier: 'https://cocina.sul.stanford.edu/file/278e1cb1-929a-41ef-af04-c89d785804dd',
                                                label: 'sub/image113.tif',
                                                filename: 'sub/image113.tif',
                                                size: 0,
                                                version: 1,
                                                hasMessageDigests: [],
                                                access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                administrative: { publish: false, sdrPreserve: true, shelve: false } }] } },
                   # This file does not exist in the workspace.
                   { type: Cocina::Models::FileSetType.image,
                     externalIdentifier: 'bb222cc3333_4',
                     label: 'Image 4',
                     version: 1,
                     structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                externalIdentifier: 'https://cocina.sul.stanford.edu/file/ced39e5f-ff5d-4b76-b688-22369e410f4c',
                                                label: 'image114.tif',
                                                filename: 'image114.tif',
                                                size: 1234,
                                                version: 1,
                                                hasMessageDigests: [{ type: 'md5', digest: 'bd440802bd590ce0899dafecc5a5ab2c' },
                                                                    { type: 'sha1', digest: '6d9f6dc2ca4fd3329619b54a2c6f99a08c088455' }],
                                                access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
        hasMemberOrders: [],
        isMemberOf: [] }
    end

    let(:assembly_item) { Dor::Assembly::Item.new(druid: bare_druid) }

    it 'computes checksums' do
      file_sets = robot.send(:compute_checksums, assembly_item, cocina_object)
      files = file_sets.flat_map { |fs| fs[:structural][:contains] }
      digests = files.map { |file| file[:hasMessageDigests] }
      expect(digests).to eq [
        [
          {
            type: 'md5',
            digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794'
          },
          {
            type: 'sha1',
            digest: '77795223379bdb0ded2bd5b8a63adc07fb1c3484'
          }
        ],
        [
          {
            type: 'sha1',
            digest: '5c9f6dc2ca4fd3329619b54a2c6f99a08c088444'
          },
          {
            type: 'md5',
            digest: 'ac440802bd590ce0899dafecc5a5ab1b'
          }
        ],
        [
          {
            type: 'md5',
            digest: 'ac440802bd590ce0899dafecc5a5ab1b'
          },
          {
            type: 'sha1',
            digest: '5c9f6dc2ca4fd3329619b54a2c6f99a08c088444'
          }
        ],
        [
          {
            type: 'md5',
            digest: 'bd440802bd590ce0899dafecc5a5ab2c'
          },
          {
            type: 'sha1',
            digest: '6d9f6dc2ca4fd3329619b54a2c6f99a08c088455'
          }
        ]
      ]
    end

    it 'errors with a useful message when checksums do not match' do
      structural[:contains].first[:structural][:contains].first[:hasMessageDigests].first[:digest] = '666'
      cocina_object = build(:dro, id: druid).new(structural:)
      expect { robot.send(:compute_checksums, assembly_item, cocina_object) }.to raise_error(RuntimeError, /Checksums disagree: type="md5", file="image111.tif"/)
    end
  end
end
