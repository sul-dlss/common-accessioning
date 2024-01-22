# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::Jp2Create do
  let(:robot) { described_class.new }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model, update: true)
  end
  let(:access) { { view: 'world' } }
  let(:druid) { "druid:#{bare_druid}" }
  let(:cocina_model) { build(:dro, id: druid).new(structural:, access:) }

  let(:structural) do
    { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                   externalIdentifier: 'bb111bb2222_1',
                   label: 'Image 1',
                   version: 1,
                   structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                              externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
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
                                              externalIdentifier: 'https://cocina.sul.stanford.edu/file/39a83c02-5d05-4c3d-bff1-080772cfdd99',
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
                                              externalIdentifier: 'https://cocina.sul.stanford.edu/file/c7644dd4-a577-4a45-8e7e-addb711191ec',
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

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  describe '#perform' do
    subject(:perform) { test_perform(robot, druid) }

    let(:assembly_item) { Dor::Assembly::Item.new(druid: bare_druid) }
    let(:bare_druid) { 'bb222cc3333' }

    before do
      allow(robot).to receive(:assembly_item).and_return(assembly_item)
    end

    context 'with an item' do
      let(:object) { build(:dro, id: druid) }

      before do
        allow(assembly_item).to receive(:item?).and_call_original
      end

      it 'creates jp2' do
        allow(robot).to receive(:create_jp2s).with(assembly_item, cocina_model).and_return([])
        perform
        expect(assembly_item).to have_received(:item?)
      end

      context 'with dark access' do
        let(:access) { { view: 'dark' } }

        it 'does not create jp2' do
          expect(perform.status).to eq 'skipped'
        end
      end
    end

    context 'with a collection' do
      let(:object) { build(:collection, id: druid) }

      it 'does not create jp2' do
        expect(assembly_item).to receive(:item?)
        expect(robot).not_to receive(:create_jp2s).with(assembly_item, cocina_model)
        perform
      end
    end
  end

  describe '#create_jp2s' do
    before do
      clone_test_input TMP_ROOT_DIR
      # Ensure the files we modifiy are in tmp/
      allow(Settings.assembly).to receive(:root_dir).and_return(TMP_ROOT_DIR)
      allow(Assembly::Image).to receive(:new).and_return(assembly_image)
      allow(SecureRandom).to receive(:uuid).and_return('f468bd97-9eda-44ce-b505-3d5dd6a6c833')
    end

    let(:assembly_image) { instance_double(Assembly::Image, create_jp2: true, path: image_filepath, jp2_filename: jp2_filepath) }

    let(:file_sets) do
      robot.send(:create_jp2s, Dor::Assembly::Item.new(druid: bare_druid), cocina_model)
    end

    let(:bare_druid) { 'ff222cc3333' }

    let(:image_filepath) { "#{TMP_ROOT_DIR}/ff/222/cc/3333/image111.tif" }
    let(:jp2_filepath) { "#{TMP_ROOT_DIR}/ff/222/cc/3333/image111.jp2" }

    context 'with a fileset that is not page or image' do
      let(:structural) do
        # This is an audio fileset (but contains an image for testing)
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/audio',
                       externalIdentifier: 'bb111bb2222_1',
                       label: 'Image 1',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                                  label: 'image111.tif',
                                                  filename: 'image111.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      it 'does not change the fileset or create jp2' do
        expect(file_sets).to eq(structural[:contains])
        expect(File.exist?("#{TMP_ROOT_DIR}/ff/222/cc/3333/image111.jp2")).to be false
      end
    end

    context 'with a file that has an existing mimetype that is not an image' do
      let(:structural) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/page',
                       externalIdentifier: 'bb111bb2222_1',
                       label: 'Doc 1',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                                  label: 'doc111.pdf',
                                                  filename: 'doc111.pdf',
                                                  size: 0,
                                                  version: 1,
                                                  # With hasMimetype
                                                  hasMimeType: 'application/pdf',
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      it 'does not change the fileset or create jp2' do
        expect(file_sets).to eq(structural[:contains])
        expect(assembly_image).not_to have_received(:create_jp2)
      end
    end

    context 'with a file that does not have an existing mimetype and is not an image' do
      let(:structural) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/page',
                       externalIdentifier: 'bb111bb2222_1',
                       label: 'Doc 1',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                                  label: 'doc111.pdf',
                                                  filename: 'doc111.pdf',
                                                  size: 0,
                                                  version: 1,
                                                  # No hasMimeType
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      it 'does not change the fileset or create jp2' do
        expect(file_sets).to eq(structural[:contains])
        expect(File.exist?("#{TMP_ROOT_DIR}/ff/222/cc/3333/doc111.pdf")).to be true
        expect(assembly_image).not_to have_received(:create_jp2)
      end
    end

    context 'when the image file does not exist and there is a jp2 cocina file and jp2 file' do
      let(:structural) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'bb111bb2222_1',
                       label: 'Image 4',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                                  label: 'image114.tif',
                                                  filename: 'image114.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                                  label: 'image114.jp2',
                                                  filename: 'image114.jp2',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      it 'does not change the fileset or create jp2' do
        expect(file_sets).to eq(structural[:contains])
        expect(assembly_image).not_to have_received(:create_jp2)
      end
    end

    context 'when the image file exists and there is a jp2 cocina file and a jp2 file' do
      let(:image_filepath) { "#{TMP_ROOT_DIR}/ff/222/cc/3333/image112.tif" }
      let(:jp2_filepath) { "#{TMP_ROOT_DIR}/ff/222/cc/3333/image112.jp2" }

      let(:structural) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'bb111bb2222_1',
                       label: 'Image 2',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                                  label: 'image112.tif',
                                                  filename: 'image112.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                                  label: 'image112.jp2',
                                                  filename: 'image112.jp2',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      it 'does not change the fileset or create jp2' do
        expect(file_sets).to eq(structural[:contains])
        expect(assembly_image).not_to have_received(:create_jp2)
      end
    end

    context 'when the image file exists and there is a jp2 cocina file' do
      let(:structural) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'bb111bb2222_1',
                       label: 'Image 1',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                                  label: 'image111.tif',
                                                  filename: 'image111.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                                  label: 'image111.jp2',
                                                  filename: 'image111.jp2',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      it 'replaces the jp2 cocina file and creates a jp2 file' do
        expect(file_sets).to eq(
          [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
             externalIdentifier: 'bb111bb2222_1',
             label: 'Image 1',
             version: 1,
             structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                        externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                        label: 'image111.tif',
                                        filename: 'image111.tif',
                                        size: 0,
                                        version: 1,
                                        hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                        access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                        administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                      { type: 'https://cocina.sul.stanford.edu/models/file',
                                        externalIdentifier: 'https://cocina.sul.stanford.edu/file/f468bd97-9eda-44ce-b505-3d5dd6a6c833',
                                        label: 'image111.jp2',
                                        filename: 'image111.jp2',
                                        version: 1,
                                        hasMessageDigests: [],
                                        hasMimeType: 'image/jp2',
                                        access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                        administrative: { publish: true, sdrPreserve: false, shelve: true } }] } }]
        )
        expect(assembly_image).to have_received(:create_jp2)
      end
    end

    context 'when the image file exists and there is a jp2 file but no jp2 cocina file' do
      let(:image_filepath) { "#{TMP_ROOT_DIR}/ff/222/cc/3333/image112.tif" }
      let(:jp2_filepath) { "#{TMP_ROOT_DIR}/ff/222/cc/3333/image112.jp2" }

      let(:structural) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'bb111bb2222_1',
                       label: 'Image 2',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                                  label: 'image112.tif',
                                                  filename: 'image112.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      it 'creates a jp2 cocina file' do
        expect(File.exist?("#{TMP_ROOT_DIR}/ff/222/cc/3333/image112.jp2")).to be true
        expect(file_sets).to eq(
          [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
             externalIdentifier: 'bb111bb2222_1',
             label: 'Image 2',
             version: 1,
             structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                        externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                        label: 'image112.tif',
                                        filename: 'image112.tif',
                                        size: 0,
                                        version: 1,
                                        hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                        access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                        administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                      { type: 'https://cocina.sul.stanford.edu/models/file',
                                        externalIdentifier: 'https://cocina.sul.stanford.edu/file/f468bd97-9eda-44ce-b505-3d5dd6a6c833',
                                        label: 'image112.jp2',
                                        filename: 'image112.jp2',
                                        version: 1,
                                        hasMessageDigests: [],
                                        hasMimeType: 'image/jp2',
                                        access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                        administrative: { publish: true, sdrPreserve: false, shelve: true } }] } }]
        )
        expect(assembly_image).not_to have_received(:create_jp2)
        expect(File.exist?("#{TMP_ROOT_DIR}/ff/222/cc/3333/image112.jp2")).to be true
      end
    end

    context 'when the hierarchical image file exists and there is a jp2 file but no jp2 cocina file' do
      let(:image_filepath) { "#{TMP_ROOT_DIR}/ff/222/cc/3333/sub/image113.tif" }
      let(:jp2_filepath) { "#{TMP_ROOT_DIR}/ff/222/cc/3333/sub/image113.jp2" }

      let(:structural) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'bb111bb2222_1',
                       label: 'Image 3',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                                  label: 'sub/image113.tif',
                                                  filename: 'sub/image113.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      it 'adds the jp2 cocina file' do
        expect(File.exist?("#{TMP_ROOT_DIR}/ff/222/cc/3333/sub/image113.jp2")).to be true
        expect(file_sets).to eq(
          [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
             externalIdentifier: 'bb111bb2222_1',
             label: 'Image 3',
             version: 1,
             structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                        externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                        label: 'sub/image113.tif',
                                        filename: 'sub/image113.tif',
                                        size: 0,
                                        version: 1,
                                        hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                        access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                        administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                      { type: 'https://cocina.sul.stanford.edu/models/file',
                                        externalIdentifier: 'https://cocina.sul.stanford.edu/file/f468bd97-9eda-44ce-b505-3d5dd6a6c833',
                                        label: 'sub/image113.jp2',
                                        filename: 'sub/image113.jp2',
                                        version: 1,
                                        hasMessageDigests: [],
                                        hasMimeType: 'image/jp2',
                                        access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                        administrative: { publish: true, sdrPreserve: false, shelve: true } }] } }]
        )
        expect(assembly_image).not_to have_received(:create_jp2)
        expect(File.exist?("#{TMP_ROOT_DIR}/ff/222/cc/3333/sub/image113.jp2")).to be true
      end
    end

    context 'when the image file does not exist and there is no jp2 file' do
      let(:image_filepath) { "#{TMP_ROOT_DIR}/ff/222/cc/3333/image114.tif" }
      let(:structural) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'bb111bb2222_1',
                       label: 'Image 4',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                                  label: 'image114.tif',
                                                  filename: 'image114.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end
      let(:jp2_filepath) { "#{TMP_ROOT_DIR}/ff/222/cc/3333/image114.jp2" }

      let(:client) { instance_double(Preservation::Client, objects: objects_client) }
      let(:objects_client) { instance_double(Preservation::Client::Objects) }

      before do
        allow(Preservation::Client).to receive(:configure).and_return(client)
        allow(objects_client).to receive(:content) do |*args|
          args.first.fetch(:on_data).call('a tiff')
        end
      end

      it 'retrieves the file from preservation and creates a jp2' do
        expect(file_sets).to eq(
          [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
             externalIdentifier: 'bb111bb2222_1',
             label: 'Image 4',
             version: 1,
             structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                        externalIdentifier: 'https://cocina.sul.stanford.edu/file/d30f48f9-1c11-4290-95a4-fea64e346db9',
                                        label: 'image114.tif',
                                        filename: 'image114.tif',
                                        size: 0,
                                        version: 1,
                                        hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                        access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                        administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                      { type: 'https://cocina.sul.stanford.edu/models/file',
                                        externalIdentifier: 'https://cocina.sul.stanford.edu/file/f468bd97-9eda-44ce-b505-3d5dd6a6c833',
                                        label: 'image114.jp2',
                                        filename: 'image114.jp2',
                                        version: 1,
                                        hasMessageDigests: [],
                                        hasMimeType: 'image/jp2',
                                        access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                        administrative: { publish: true, sdrPreserve: false, shelve: true } }] } }]
        )
        expect(assembly_image).to have_received(:create_jp2)
        expect(objects_client).to have_received(:content).with(druid: bare_druid,
                                                               filepath: 'image114.tif',
                                                               on_data: Proc)
        expect(File.exist?("#{TMP_ROOT_DIR}/ff/222/cc/3333/image114.tif")).to be true
        expect(File.exist?("#{TMP_ROOT_DIR}/ff/222/cc/3333/image114.jp2")).to be false
      end
    end
  end
end
