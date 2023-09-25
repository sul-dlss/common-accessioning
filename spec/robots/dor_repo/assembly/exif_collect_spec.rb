# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::ExifCollect do
  let(:robot) { described_class.new }
  let(:druid) { 'druid:bb222cc3333' }
  let(:type) { 'item' }
  let(:item) do
    instance_double(Dor::Assembly::Item,
                    cocina_model:,
                    object_client:,
                    druid:,
                    item?: type == 'item')
  end
  let(:structural) { {} }
  let(:cocina_model) { build(:dro, id: druid).new(structural:) }

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, update: true)
  end

  before do
    allow(Dor::Assembly::Item).to receive(:new).and_return(item)
  end

  describe '#perform' do
    subject(:perform) { test_perform(robot, druid) }

    context "when it's an item" do
      before do
        allow(robot).to receive(:collect_exif_info).and_return([])
      end

      it 'collects exif' do
        perform
        expect(object_client).to have_received(:update)
      end
    end

    context "when it's a set" do
      let(:type) { 'set' }

      it 'does not collect exif' do
        expect(robot).not_to receive(:collect_exif_info)
        perform
      end
    end
  end

  describe '#collect_exif_infos' do
    subject(:result) { robot.send(:collect_exif_infos, item, cocina_model) }

    let(:item) { Dor::Assembly::Item.new(druid:) }

    let(:exif) { double('result', mimetype: nil, imagewidth: 7, imageheight: 9) }

    before do
      allow(item).to receive_messages(item?: true, druid: 'foo:999')
      allow(item).to receive(:load_content_metadata)
    end

    context 'when there are no existing mimetypes and filesizes in file nodes' do
      let(:structural) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'bb111bb2222_1',
                       label: 'Image 1',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/adb98474-98a6-4f12-bef8-3ffb249153b1',
                                                  label: 'image111.tif',
                                                  filename: 'image111.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'bb111bb2222_2',
                       label: 'Image 2',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/f76ee0bc-45d2-4989-b76f-9b973d773e39',
                                                  label: 'image112.tif',
                                                  filename: 'image112.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'sha1', digest: '5c9f6dc2ca4fd3329619b54a2c6f99a08c088444' },
                                                                      { type: 'md5', digest: 'ac440802bd590ce0899dafecc5a5ab1b' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'bb111bb2222_3',
                       label: 'Image 3',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/b63faebf-7204-4e3e-ae29-255315480add',
                                                  label: 'sub/image113.tif',
                                                  filename: 'sub/image113.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      let(:druid) { 'druid:bb111bb2222' }

      before do
        allow(Assembly::ObjectFile).to receive(:new).and_return(
          instance_double(Assembly::ObjectFile, mimetype: 'image/tiff', filesize: 63_468, valid_image?: true, exif:),
          instance_double(Assembly::ObjectFile, mimetype: 'image/tiff', filesize: 63_472, valid_image?: true, exif:),
          instance_double(Assembly::ObjectFile, mimetype: 'image/tiff', filesize: 63_472, valid_image?: true, exif:)
        )
      end

      it 'sets the size and mimetype' do
        file_sets = result
        # check that each file node now has size, mimetype
        files = file_sets.flat_map { |fs| fs[:structural][:contains] }
        expect(files.size).to eq(3)
        expect(files[0][:size]).to eq(63_468)
        expect(files[1][:size]).to eq(63_472)
        files.each { |file| expect(file[:hasMimeType]).to eq('image/tiff') }
        expect(files[0][:presentation]).to be_present
        expect(files[1][:presentation]).to be_present
        expect(files[2][:presentation]).to be_present
      end
    end

    context 'when there are existing mimetypes and filesizes in file nodes' do
      let(:structural) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'cc333dd4444_1',
                       label: 'Image 1',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/89f8431c-b11d-44d4-989f-638ddb5ba3fa',
                                                  label: 'image222.tif',
                                                  filename: 'image222.tif',
                                                  size: 100,
                                                  version: 1,
                                                  hasMimeType: 'crappy/mimetype',
                                                  hasMessageDigests: [{ type: 'md5', digest: '3d5812d6b2506ec96a6bdef5795a888b' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/f9beaed9-42fc-4fa1-9add-d378baedcbe5',
                                                  label: 'image222.txt',
                                                  filename: 'image222.txt',
                                                  size: 500,
                                                  version: 1,
                                                  hasMimeType: 'crappy/again',
                                                  hasMessageDigests: [{ type: 'md5', digest: '0929b8b53d900da1ddd1603ec7f29c36' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/g0beaed9-42fc-4fa1-9add-d378baedcbf6',
                                                  label: 'image223.txt',
                                                  # This file does not exist so exif info should be maintained.
                                                  filename: 'image223.txt',
                                                  size: 550,
                                                  version: 1,
                                                  hasMimeType: 'text/plain',
                                                  hasMessageDigests: [{ type: 'md5', digest: '0929b8b53d900da1ddd1603ec7f29c36' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      let(:druid) { 'druid:cc333dd4444' }

      it 'does not overwrite them' do
        file_sets = result
        # check that the file nodes still have bogus size, mimetype
        files = file_sets.flat_map { |fs| fs[:structural][:contains] }
        expect(files.size).to eq(3)
        expect(files[0][:size]).to eq(100)
        expect(files[0][:hasMimeType]).to eq('crappy/mimetype')
        expect(files[1][:size]).to eq(500)
        expect(files[1][:hasMimeType]).to eq('crappy/again')
        expect(files[2][:size]).to eq(550)
        expect(files[2][:hasMimeType]).to eq('text/plain')

        expect(files[0][:presentation]).to be_present
        expect(files[1][:presentation]).not_to be_present
      end
    end
  end
end
