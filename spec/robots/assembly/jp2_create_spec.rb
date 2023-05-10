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
    end

    let(:item) do
      Dor::Assembly::Item.new(druid: bare_druid)
    end

    context 'when resource type is not specified' do
      let(:bare_druid) { 'bb111bb2222' }

      before do
        allow_any_instance_of(Assembly::ObjectFile).to receive(:jp2able?).and_return(true)
        allow_any_instance_of(Assembly::Image).to receive(:create_jp2).with(overwrite: false, tmp_folder: '/tmp').and_return(instance_double(Assembly::Image, path: 'spec/out/image111.jp2'))
      end

      it 'does not create any jp2 files' do
        # We now have jp2s since all resource types = image
        file_sets = robot.send(:create_jp2s, item, cocina_model)
        files = file_sets.flat_map { |fs| fs[:structural][:contains] }
        expect(files.size).to eq(6)
        expect(files.filter { |file| file[:filename].end_with?('.tif') }.size).to eq 3
        expect(files.filter { |file| file[:filename].end_with?('.jp2') }.size).to eq 3
      end
    end

    context 'with mixed resource types' do
      let(:bare_druid) { 'ff222cc3333' }

      let(:structural) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/file',
                       externalIdentifier: 'ff222cc3333_1',
                       label: 'Side 1',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/23678d76-ae89-4691-bdda-aee2d459ad56',
                                                  label: 'image111.tif',
                                                  filename: 'image111.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: true, sdrPreserve: true, shelve: true } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d9db6ba3-bf6e-4346-a890-3e4fa28b2f48',
                                                  label: 'image111.jp2',
                                                  filename: 'image111.jp2',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d14bbadd-0886-4113-b6ca-3fbe3fcbcbf6',
                                                  label: 'file111.wav',
                                                  filename: 'file111.wav',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef7XX' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/c4e832c5-ff2f-4bcd-a347-0880d9365e94',
                                                  label: 'file111.pdf',
                                                  filename: 'file111.pdf',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef7XX' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/file',
                       externalIdentifier: 'ff222cc3333_2',
                       label: 'Side 2',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/ef6b789a-7e4e-48e8-9d92-4f09afbd0d71',
                                                  label: 'file112.pdf',
                                                  filename: 'file112.pdf',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef7XX' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/2b6cc6d6-bbf9-4721-beba-78f8e2e6cb96',
                                                  label: 'image112.tif',
                                                  filename: 'image112.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/99965f50-62d9-4ee6-82b2-4c0d41a6fa29',
                                                  label: 'file111.mp3',
                                                  filename: 'file111.mp3',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef7XX' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/file',
                       externalIdentifier: 'ff222cc3333_3',
                       label: 'Side 3',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/1b145041-2fd0-4026-afb8-5bdfee9dd47a',
                                                  label: 'image113.tif',
                                                  filename: 'image113.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/page',
                       externalIdentifier: 'ff222cc3333_3',
                       label: 'Side 3',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/84a9367f-5130-436a-8e48-79ea186da404',
                                                  label: 'image114.tif',
                                                  filename: 'image114.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'ff222cc3333_3',
                       label: 'Side 4',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/ddb7881a-2bcd-4d9f-ab41-7f264537ebe6',
                                                  label: 'image115.tif',
                                                  filename: 'image115.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      before do
        allow_any_instance_of(Assembly::ObjectFile).to receive(:jp2able?).and_return(true)
      end

      it 'creates jp2 files only for resource type image or page' do
        expect(robot).to receive(:create_jp2).twice
        robot.send(:create_jp2s, item, cocina_model)
      end
    end

    context 'with resource type image or page in new location' do
      let(:bare_druid) { 'gg111bb2222' }
      let(:structural) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'gg111bb2222_1',
                       label: 'Image 1',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/674e1e0a-4206-49d6-9bea-84cb1406735b',
                                                  label: 'image111.tif',
                                                  filename: 'image111.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'gg111bb2222_2',
                       label: 'Image 2',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/f49631eb-333e-4ecd-b7b9-fe06fea42441',
                                                  label: 'image112.tif',
                                                  filename: 'image112.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'sha1', digest: '5c9f6dc2ca4fd3329619b54a2c6f99a08c088444' },
                                                                      { type: 'md5', digest: 'ac440802bd590ce0899dafecc5a5ab1b' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'gg111bb2222_3',
                       label: 'Image 3',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/eaaab63f-ae01-46b0-af25-82f545e6e427',
                                                  label: 'sub/image113.tif',
                                                  filename: 'sub/image113.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      before do
        allow(item).to receive(:cm_file_name).and_return(item.path_finder.path_to_metadata_file(Settings.assembly.cm_file_name))
        allow_any_instance_of(Assembly::ObjectFile).to receive(:jp2able?).and_return(true)

        # These files needs to create
        d1 = instance_double(Assembly::Image, path: 'spec/out/image111.jp2')
        s1 = Assembly::Image.new('tmp/test_input/gg/111/bb/2222/gg111bb2222/content/image111.tif')
        allow(s1).to receive(:create_jp2).and_return(d1)

        # These files needs to create
        d2 = instance_double(Assembly::Image, path: 'spec/out/image112.jp2')
        s2 = Assembly::Image.new('tmp/test_input/gg/111/bb/2222/gg111bb2222/content/image112.tif')
        allow(s2).to receive(:create_jp2).and_return(d2)

        # These files needs to create
        d3 = instance_double(Assembly::Image, path: 'spec/out/image113.jp2')
        s3 = Assembly::Image.new('tmp/test_input/gg/111/bb/2222/gg111bb2222/content/image113.tif')
        allow(s3).to receive(:create_jp2).and_return(d3)

        allow(Assembly::Image).to receive(:new).and_return(s1, s2, s3)
      end

      it 'creates jp2 files only for the resource type image or page in new location' do
        file_sets = robot.send(:create_jp2s, item, cocina_model)

        # We now have three jp2s
        filenames = file_sets.flat_map { |fs| fs[:structural][:contains] }.map { |file| file[:filename] }
        expect(filenames).to contain_exactly('image111.jp2', 'image111.tif', 'image112.jp2', 'image112.tif', 'sub/image113.jp2', 'sub/image113.tif')
      end
    end

    context 'when some files exist' do
      let(:bare_druid) { 'ff222cc3333' }

      let(:structural) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/file',
                       externalIdentifier: 'ff222cc3333_1',
                       label: 'Side 1',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/23678d76-ae89-4691-bdda-aee2d459ad56',
                                                  label: 'image111.tif',
                                                  filename: 'image111.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: true, sdrPreserve: true, shelve: true } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d9db6ba3-bf6e-4346-a890-3e4fa28b2f48',
                                                  label: 'image111.jp2',
                                                  filename: 'image111.jp2',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d14bbadd-0886-4113-b6ca-3fbe3fcbcbf6',
                                                  label: 'file111.wav',
                                                  filename: 'file111.wav',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef7XX' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/c4e832c5-ff2f-4bcd-a347-0880d9365e94',
                                                  label: 'file111.pdf',
                                                  filename: 'file111.pdf',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef7XX' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/file',
                       externalIdentifier: 'ff222cc3333_2',
                       label: 'Side 2',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/ef6b789a-7e4e-48e8-9d92-4f09afbd0d71',
                                                  label: 'file112.pdf',
                                                  filename: 'file112.pdf',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef7XX' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/2b6cc6d6-bbf9-4721-beba-78f8e2e6cb96',
                                                  label: 'image112.tif',
                                                  filename: 'image112.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/99965f50-62d9-4ee6-82b2-4c0d41a6fa29',
                                                  label: 'file111.mp3',
                                                  filename: 'file111.mp3',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef7XX' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/file',
                       externalIdentifier: 'ff222cc3333_3',
                       label: 'Side 3',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/1b145041-2fd0-4026-afb8-5bdfee9dd47a',
                                                  label: 'image113.tif',
                                                  filename: 'image113.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/page',
                       externalIdentifier: 'ff222cc3333_3',
                       label: 'Side 3',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/84a9367f-5130-436a-8e48-79ea186da404',
                                                  label: 'image114.tif',
                                                  filename: 'image114.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'ff222cc3333_3',
                       label: 'Side 4',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/ddb7881a-2bcd-4d9f-ab41-7f264537ebe6',
                                                  label: 'image115.tif',
                                                  filename: 'image115.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'md5', digest: '42616f9e6c1b7e7b7a71b4fa0c5ef794' }],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      let(:copy_jp2) { File.join TMP_ROOT_DIR, 'ff/222/cc/3333', 'image115.jp2' }

      before do
        # copy an existing jp2
        source_jp2 = File.join TMP_ROOT_DIR, 'ff/222/cc/3333', 'image111.jp2'
        system "cp #{source_jp2} #{copy_jp2}"

        allow_any_instance_of(Assembly::ObjectFile).to receive(:jp2able?).and_return(true)
        out1 = 'tmp/test_input/ff/222/cc/3333/image114.jp2'
        d1 = instance_double(Assembly::Image, path: out1)
        s1 = instance_double(Assembly::Image, 'source 1', jp2_filename: out1, path: 'tmp/test_input/ff/222/cc/3333/image114.tif', create_jp2: d1)
        s2 = instance_double(Assembly::Image, 'source 2', jp2_filename: copy_jp2, path: 'tmp/test_input/ff/222/cc/3333/image115.tif')
        allow(Assembly::Image).to receive(:new).and_return(s1, s2)
      end

      after do
        # cleanup copied jp2
        system "rm #{copy_jp2}"
      end

      it 'does not overwrite existing jp2s but should not fail either' do
        expect(File.exist?(copy_jp2)).to be(true)

        file_sets = robot.send(:create_jp2s, item, cocina_model)
        files = file_sets.flat_map { |fs| fs[:structural][:contains] }
        expect(files.size).to eq(12)
        expect(files.filter { |file| file[:filename].end_with?('.tif') }.size).to eq 5
        expect(files.filter { |file| file[:filename].end_with?('.jp2') }.size).to eq 3
      end
    end

    context 'when there is a jp2 already there' do
      let(:bare_druid) { 'hh222cc3333' }

      # This file does not need to create
      let(:source1) do
        Assembly::Image.new('tmp/test_input/hh/222/cc/3333/hh222cc3333_00_001.tif')
      end

      let(:structural) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'hh2222cc3333_1',
                       label: 'Image 1',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/796b2b81-9a2a-4d9c-b690-afccfe5300b4',
                                                  label: 'hh222cc3333_00_001.tif',
                                                  filename: 'hh222cc3333_00_001.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } },
                                                { type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/661f8462-e0c2-49c4-b617-4d5c11a969b7',
                                                  label: 'hh222cc3333_00_001.jp2',
                                                  filename: 'hh222cc3333_00_001.jp2',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'hh2222cc3333_2',
                       label: 'Image 2',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/d181310d-4026-4047-ada9-eb8cc4e2219a',
                                                  label: 'hh222cc3333_00_002.tif',
                                                  filename: 'hh222cc3333_00_002.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'hh2222cc3333_3',
                       label: 'Image 3',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/58db65e0-5169-44b0-b870-84d4b57b45a0',
                                                  label: 'hh222cc3333_00_003.tif',
                                                  filename: 'hh222cc3333_00_003.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'hh2222cc3333_3',
                       label: 'Image 4',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/c01ee082-5ef5-41bd-9efe-d508cb51eda3',
                                                  label: 'hh222cc3333_00_004.tif',
                                                  filename: 'hh222cc3333_00_004.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'hh2222cc3333_3',
                       label: 'Image 5',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/47fe008f-9a2b-4d30-9e60-f6c3485ba700',
                                                  label: 'hh222cc3333_00_005.tif',
                                                  filename: 'hh222cc3333_00_005.tif',
                                                  size: 0,
                                                  version: 1,
                                                  hasMessageDigests: [],
                                                  access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      let(:jp2_file) { instance_double(Assembly::ObjectFile, jp2able?: false, path: '') }
      let(:tiff_file) { instance_double(Assembly::ObjectFile, jp2able?: true, path: '') }

      before do
        # No need to create these jp2 files here
        d3 = instance_double(Assembly::Image, path: 'tmp/test_input/hh/222/cc/3333/hh222cc3333_00_002.jp2')
        s3 = Assembly::Image.new('tmp/test_input/hh/222/cc/3333/hh222cc3333_00_002.tif')
        allow(s3).to receive(:create_jp2).and_return(d3)

        d4 = instance_double(Assembly::Image, path: 'tmp/test_input/hh/222/cc/3333/hh222cc3333_00_003.jp2')
        s4 = Assembly::Image.new('tmp/test_input/hh/222/cc/3333/hh222cc3333_00_003.tif')
        allow(s4).to receive(:create_jp2).and_return(d4)

        d5 = instance_double(Assembly::Image, path: 'tmp/test_input/hh/222/cc/3333/hh222cc3333_00_004.jp2')
        s5 = Assembly::Image.new('tmp/test_input/hh/222/cc/3333/hh222cc3333_00_004.tif')
        allow(s5).to receive(:create_jp2).and_return(d5)

        d6 = instance_double(Assembly::Image, path: 'tmp/test_input/hh/222/cc/3333/hh222cc3333_00_005.jp2')
        s6 = Assembly::Image.new('tmp/test_input/hh/222/cc/3333/hh222cc3333_00_005.tif')
        allow(s6).to receive(:create_jp2).and_return(d6)

        allow(Assembly::Image).to receive(:new).and_return(source1, s3, s4, s5, s6)

        # This matches the order of the files in `structural', and is only necessary on CI where exif is not present
        allow(Assembly::ObjectFile).to receive(:new).and_return(tiff_file, jp2_file, tiff_file, tiff_file, tiff_file, tiff_file)
      end

      it 'does not overwrite existing jp2s' do
        file_sets = robot.send(:create_jp2s, item, cocina_model)
        files = file_sets.flat_map { |fs| fs[:structural][:contains] }
        expect(files.size).to eq(10)
        expect(files.filter { |file| file[:filename].end_with?('.tif') }.size).to eq 5
        expect(files.filter { |file| file[:filename].end_with?('.jp2') }.size).to eq 5
      end
    end
  end

  describe '#add_jp2_file_node' do
    let(:bare_druid) { 'bb111bb2222' }

    let(:file_node) do
      file_set.dig(:structural, :contains, 0)
    end

    before do
      allow(SecureRandom).to receive(:uuid).and_return('1')
    end

    context 'when jp2 file node does not exist' do
      let(:file_set) do
        { type: 'https://cocina.sul.stanford.edu/models/resources/image',
          externalIdentifier: 'hh2222cc3333_1',
          label: 'Image 1',
          version: 1,
          structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                     externalIdentifier: 'https://cocina.sul.stanford.edu/file/796b2b81-9a2a-4d9c-b690-afccfe5300b4',
                                     label: 'foo.tif',
                                     filename: 'foo.tif',
                                     size: 0,
                                     version: 1,
                                     hasMessageDigests: [],
                                     access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                     administrative: { publish: false, sdrPreserve: false, shelve: false } }] } }
      end

      let(:expected_fileset) do
        { type: 'https://cocina.sul.stanford.edu/models/resources/image',
          externalIdentifier: 'hh2222cc3333_1',
          label: 'Image 1',
          version: 1,
          structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                     externalIdentifier: 'https://cocina.sul.stanford.edu/file/796b2b81-9a2a-4d9c-b690-afccfe5300b4',
                                     label: 'foo.tif',
                                     filename: 'foo.tif',
                                     size: 0,
                                     version: 1,
                                     hasMessageDigests: [],
                                     access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                     administrative: { publish: false, sdrPreserve: false, shelve: false } },
                                   { type: 'https://cocina.sul.stanford.edu/models/file',
                                     externalIdentifier: 'https://cocina.sul.stanford.edu/file/1',
                                     label: 'foo.jp2',
                                     filename: 'foo.jp2',
                                     version: 1,
                                     hasMessageDigests: [],
                                     hasMimeType: 'image/jp2',
                                     access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                     administrative: { publish: true, sdrPreserve: false, shelve: true } }] } }
      end

      it 'adds a File node to the passed in FileSet' do
        robot.send :add_jp2_file_node, file_set, cocina_model, 'foo.jp2'
        expect(file_set).to eq expected_fileset
      end
    end

    context 'when jp2 file node already exists' do
      let(:file_set) do
        { type: 'https://cocina.sul.stanford.edu/models/resources/image',
          externalIdentifier: 'hh2222cc3333_1',
          label: 'Image 1',
          version: 1,
          structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                     externalIdentifier: 'https://cocina.sul.stanford.edu/file/796b2b81-9a2a-4d9c-b690-afccfe5300b4',
                                     label: 'foo.tif',
                                     filename: 'foo.tif',
                                     size: 0,
                                     version: 1,
                                     hasMessageDigests: [],
                                     access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                     administrative: { publish: false, sdrPreserve: false, shelve: false } },
                                   { type: 'https://cocina.sul.stanford.edu/models/file',
                                     externalIdentifier: 'https://cocina.sul.stanford.edu/file/661f8462-e0c2-49c4-b617-4d5c11a969b7',
                                     label: 'foo.jp2',
                                     filename: 'foo.jp2',
                                     version: 1,
                                     hasMessageDigests: [],
                                     access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                     administrative: { publish: false, sdrPreserve: false, shelve: false } }] } }
      end

      let(:expected_fileset) do
        { type: 'https://cocina.sul.stanford.edu/models/resources/image',
          externalIdentifier: 'hh2222cc3333_1',
          label: 'Image 1',
          version: 1,
          structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                     externalIdentifier: 'https://cocina.sul.stanford.edu/file/796b2b81-9a2a-4d9c-b690-afccfe5300b4',
                                     label: 'foo.tif',
                                     filename: 'foo.tif',
                                     size: 0,
                                     version: 1,
                                     hasMessageDigests: [],
                                     access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                     administrative: { publish: false, sdrPreserve: false, shelve: false } },
                                   { type: 'https://cocina.sul.stanford.edu/models/file',
                                     externalIdentifier: 'https://cocina.sul.stanford.edu/file/661f8462-e0c2-49c4-b617-4d5c11a969b7',
                                     label: 'foo.jp2',
                                     filename: 'foo.jp2',
                                     version: 1,
                                     hasMessageDigests: [],
                                     access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                     administrative: { publish: false, sdrPreserve: false, shelve: false } },
                                   { type: 'https://cocina.sul.stanford.edu/models/file',
                                     externalIdentifier: 'https://cocina.sul.stanford.edu/file/1',
                                     label: 'foo.jp2',
                                     filename: 'foo.jp2',
                                     version: 1,
                                     hasMessageDigests: [],
                                     hasMimeType: 'image/jp2',
                                     access: { view: 'world', download: 'none', controlledDigitalLending: false },
                                     administrative: { publish: true, sdrPreserve: false, shelve: true } }] } }
      end

      it 'adds a new jp2 File node on the passed in FileSet' do
        robot.send :add_jp2_file_node, file_set, cocina_model, 'foo.jp2'
        expect(file_set).to eq expected_fileset
      end
    end
  end
end
