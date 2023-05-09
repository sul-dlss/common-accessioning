# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Assembly::ContentMetadataFromStub::StructuralBuilder do
  let(:test_input_dir) { File.join(__dir__, '../../../../fixtures/content_metadata') }

  describe '.build' do
    subject(:result) { described_class.build(cocina_model:, objects:) }

    let(:druid) { 'druid:nx288wh8889' }
    let(:cocina_model) { build(:dro, id: druid, type: object_type) }
    let(:file_attributes) { { publish: 'no', preserve: 'yes', shelve: 'no' } }

    before do
      allow(SecureRandom).to receive(:uuid).and_return(*1.upto(16).map(&:to_s))
    end

    context 'when object_type=image' do
      let(:object_type) { Cocina::Models::ObjectType.image }

      context 'when using a single tif and jp2' do
        let(:objects) do
          [[Assembly::ObjectFile.new(File.join(test_input_dir, 'test.tif'), file_attributes: { publish: 'no', preserve: 'no', shelve: 'no' })],
           [Assembly::ObjectFile.new(File.join(test_input_dir, 'test.jp2'), file_attributes: { publish: 'yes', preserve: 'yes', shelve: 'yes' })],
           [Assembly::ObjectFile.new(File.join(test_input_dir, 'test2.jp2'), file_attributes:)]]
        end

        let(:expected) do
          { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                         externalIdentifier: 'nx288wh8889_1',
                         label: 'Image 1',
                         version: 1,
                         structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/1',
                                                    label: 'test.tif',
                                                    filename: 'test.tif',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                       { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                         externalIdentifier: 'nx288wh8889_2',
                         label: 'Image 2',
                         version: 1,
                         structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/2',
                                                    label: 'test.jp2',
                                                    filename: 'test.jp2',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } }] } },
                       { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                         externalIdentifier: 'nx288wh8889_3',
                         label: 'Image 3',
                         version: 1,
                         structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/3',
                                                    label: 'test2.jp2',
                                                    filename: 'test2.jp2',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
            hasMemberOrders: [],
            isMemberOf: [] }
        end

        it 'generates valid structural metadata' do
          expect(result.to_h).to eq expected
        end
      end

      context 'when providing multiple files per resource' do
        let(:objects) do
          files = [[

            File.join(test_input_dir, 'res1_image1.tif'),
            File.join(test_input_dir, 'res1_image1.jp2'),
            File.join(test_input_dir, 'res1_image2.tif'),
            File.join(test_input_dir, 'res1_image2.jp2'),
            File.join(test_input_dir, 'res1_teifile.txt'),
            File.join(test_input_dir, 'res1_textfile.txt'),
            File.join(test_input_dir, 'res1_transcript.pdf')
          ],
                   [File.join(test_input_dir, 'res2_image1.tif'),
                    File.join(test_input_dir, 'res2_image1.jp2'),
                    File.join(test_input_dir, 'res2_image2.tif'),
                    File.join(test_input_dir, 'res2_image2.jp2'),
                    File.join(test_input_dir, 'res2_teifile.txt'),
                    File.join(test_input_dir, 'res2_textfile.txt')],
                   [File.join(test_input_dir, 'res3_image1.tif'),
                    File.join(test_input_dir, 'res3_image1.jp2'),
                    File.join(test_input_dir, 'res3_teifile.txt')]]
          files.collect { |resource| resource.collect { |file| Assembly::ObjectFile.new(file, file_attributes:) } }
        end

        let(:expected) do
          { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                         externalIdentifier: 'nx288wh8889_1',
                         label: 'Image 1',
                         version: 1,
                         structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/1',
                                                    label: 'res1_image1.tif',
                                                    filename: 'res1_image1.tif',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                  { type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/2',
                                                    label: 'res1_image1.jp2',
                                                    filename: 'res1_image1.jp2',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                  { type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/3',
                                                    label: 'res1_image2.tif',
                                                    filename: 'res1_image2.tif',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                  { type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/4',
                                                    label: 'res1_image2.jp2',
                                                    filename: 'res1_image2.jp2',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                  { type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/5',
                                                    label: 'res1_teifile.txt',
                                                    filename: 'res1_teifile.txt',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                  { type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/6',
                                                    label: 'res1_textfile.txt',
                                                    filename: 'res1_textfile.txt',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                  { type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/7',
                                                    label: 'res1_transcript.pdf',
                                                    filename: 'res1_transcript.pdf',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } }] } },
                       { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                         externalIdentifier: 'nx288wh8889_2',
                         label: 'Image 2',
                         version: 1,
                         structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/8',
                                                    label: 'res2_image1.tif',
                                                    filename: 'res2_image1.tif',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                  { type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/9',
                                                    label: 'res2_image1.jp2',
                                                    filename: 'res2_image1.jp2',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                  { type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/10',
                                                    label: 'res2_image2.tif',
                                                    filename: 'res2_image2.tif',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                  { type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/11',
                                                    label: 'res2_image2.jp2',
                                                    filename: 'res2_image2.jp2',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                  { type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/12',
                                                    label: 'res2_teifile.txt',
                                                    filename: 'res2_teifile.txt',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                  { type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/13',
                                                    label: 'res2_textfile.txt',
                                                    filename: 'res2_textfile.txt',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } }] } },
                       { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                         externalIdentifier: 'nx288wh8889_3',
                         label: 'Image 3',
                         version: 1,
                         structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/14',
                                                    label: 'res3_image1.tif',
                                                    filename: 'res3_image1.tif',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                  { type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/15',
                                                    label: 'res3_image1.jp2',
                                                    filename: 'res3_image1.jp2',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } },
                                                  { type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/16',
                                                    label: 'res3_teifile.txt',
                                                    filename: 'res3_teifile.txt',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
            hasMemberOrders: [],
            isMemberOf: [] }
        end

        it 'generates valid structural metadata for images and associated text files and no exif data' do
          expect(result.to_h).to eq expected
        end
      end
    end

    context 'when object_type=map' do
      let(:object_type) { Cocina::Models::ObjectType.map }

      context 'when using a single tif and jp2' do
        let(:objects) do
          [[Assembly::ObjectFile.new(File.join(test_input_dir, 'test.tif'), file_attributes: { publish: 'yes', preserve: 'no', shelve: 'no' })],
           [Assembly::ObjectFile.new(File.join(test_input_dir, 'test.jp2'), file_attributes: { publish: 'yes', preserve: 'yes', shelve: 'yes' })]]
        end

        let(:expected) do
          { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                         externalIdentifier: 'nx288wh8889_1',
                         label: 'Image 1',
                         version: 1,
                         structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/1',
                                                    label: 'test.tif',
                                                    filename: 'test.tif',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                       { type: 'https://cocina.sul.stanford.edu/models/resources/image',
                         externalIdentifier: 'nx288wh8889_2',
                         label: 'Image 2',
                         version: 1,
                         structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/2',
                                                    label: 'test.jp2',
                                                    filename: 'test.jp2',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
            hasMemberOrders: [],
            isMemberOf: [] }
        end

        it 'generates valid structural metadata' do
          expect(result.to_h).to eq expected
        end
      end
    end

    context 'when object_type=book' do
      let(:object_type) { Cocina::Models::ObjectType.book }

      context 'when using two tifs' do
        let(:objects) do
          [[Assembly::ObjectFile.new(File.join(test_input_dir, 'test.tif'), file_attributes:)],
           [Assembly::ObjectFile.new(File.join(test_input_dir, 'test.jp2'), file_attributes:)]]
        end

        let(:expected) do
          { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/page',
                         externalIdentifier: 'nx288wh8889_1',
                         label: 'Page 1',
                         version: 1,
                         structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/1',
                                                    label: 'test.tif',
                                                    filename: 'test.tif',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } }] } },
                       { type: 'https://cocina.sul.stanford.edu/models/resources/page',
                         externalIdentifier: 'nx288wh8889_2',
                         label: 'Page 2',
                         version: 1,
                         structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/2',
                                                    label: 'test.jp2',
                                                    filename: 'test.jp2',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
            hasMemberOrders: [
              members: [],
              viewingDirection: 'left-to-right'
            ],
            isMemberOf: [] }
        end

        it 'generates valid structural metadata for two tifs of object_type=book' do
          expect(result.to_h).to eq expected
        end
      end
    end

    context 'when object_type=object' do
      let(:object_type) { Cocina::Models::ObjectType.object }

      context 'when using two tifs and two associated jp2s' do
        let(:objects) do
          [[Assembly::ObjectFile.new(File.join(test_input_dir, 'test.tif'), file_attributes: {})],
           [Assembly::ObjectFile.new(File.join(test_input_dir, 'test.jp2'), file_attributes: {})],
           [Assembly::ObjectFile.new(File.join(test_input_dir, 'test2.tif'), file_attributes: {})],
           [Assembly::ObjectFile.new(File.join(test_input_dir, 'test2.jp2'), file_attributes: {})]]
        end

        let(:expected) do
          { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/file',
                         externalIdentifier: 'nx288wh8889_1',
                         label: 'File 1',
                         version: 1,
                         structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/1',
                                                    label: 'test.tif',
                                                    filename: 'test.tif',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                       { type: 'https://cocina.sul.stanford.edu/models/resources/file',
                         externalIdentifier: 'nx288wh8889_2',
                         label: 'File 2',
                         version: 1,
                         structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/2',
                                                    label: 'test.jp2',
                                                    filename: 'test.jp2',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                       { type: 'https://cocina.sul.stanford.edu/models/resources/file',
                         externalIdentifier: 'nx288wh8889_3',
                         label: 'File 3',
                         version: 1,
                         structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/3',
                                                    label: 'test2.tif',
                                                    filename: 'test2.tif',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: false, shelve: false } }] } },
                       { type: 'https://cocina.sul.stanford.edu/models/resources/file',
                         externalIdentifier: 'nx288wh8889_4',
                         label: 'File 4',
                         version: 1,
                         structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/4',
                                                    label: 'test2.jp2',
                                                    filename: 'test2.jp2',
                                                    version: 1,
                                                    hasMessageDigests: [],
                                                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                    administrative: { publish: false, sdrPreserve: false, shelve: false } }] } }],
            hasMemberOrders: [],
            isMemberOf: [] }
        end

        it 'generates valid structural metadata' do
          expect(result.to_h).to eq expected
        end
      end
    end

    context 'when not all input files exist' do
      let(:object_type) { Cocina::Models::ObjectType.object }
      let(:junk_file) { '/tmp/flim_flam_floom.jp2' }
      let(:objects) do
        [[Assembly::ObjectFile.new(File.join(test_input_dir, 'test.tif'), file_attributes: {})],
         [Assembly::ObjectFile.new(junk_file, file_attributes: {})]]
      end

      it 'does not generate valid structural metadata' do
        expect(File.exist?(junk_file)).to be false
        expect { result }.to raise_error(RuntimeError, "File '#{junk_file}' not found")
      end
    end

    context 'when using a 3d object with one 3d type files and three other supporting files (where one supporting file is a non-viewable but downloadable 3d file)' do
      let(:objects) do
        [[Assembly::ObjectFile.new(File.join(test_input_dir, 'someobject.obj'), file_attributes:)],
         [Assembly::ObjectFile.new(File.join(test_input_dir, 'someobject.ply'), file_attributes:)],
         [Assembly::ObjectFile.new(File.join(test_input_dir, 'test.tif'), file_attributes:)],
         [Assembly::ObjectFile.new(File.join(test_input_dir, 'test.pdf'), file_attributes:)]]
      end
      let(:object_type) { Cocina::Models::ObjectType.three_dimensional }

      let(:expected) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/3d',
                       externalIdentifier: 'nx288wh8889_1',
                       label: '3d 1',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/1',
                                                  label: 'someobject.obj',
                                                  filename: 'someobject.obj',
                                                  version: 1,
                                                  hasMessageDigests: [],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/file',
                       externalIdentifier: 'nx288wh8889_2',
                       label: 'File 1',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/2',
                                                  label: 'someobject.ply',
                                                  filename: 'someobject.ply',
                                                  version: 1,
                                                  hasMessageDigests: [],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/file',
                       externalIdentifier: 'nx288wh8889_3',
                       label: 'File 2',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/3',
                                                  label: 'test.tif',
                                                  filename: 'test.tif',
                                                  version: 1,
                                                  hasMessageDigests: [],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } },
                     { type: 'https://cocina.sul.stanford.edu/models/resources/file',
                       externalIdentifier: 'nx288wh8889_4',
                       label: 'File 3',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/4',
                                                  label: 'test.pdf',
                                                  filename: 'test.pdf',
                                                  version: 1,
                                                  hasMessageDigests: [],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      it 'generates valid structural metadata' do
        expect(result.to_h).to eq expected
      end
    end

    context 'when providing file attributes' do
      let(:object_type) { Cocina::Models::ObjectType.image }

      let(:objects) do
        [[Assembly::ObjectFile.new(File.join(test_input_dir, 'test.tif'), file_attributes: { publish: 'no', preserve: 'no', shelve: 'no', role: 'master-role' })]]
      end

      let(:expected) do
        { contains: [{ type: 'https://cocina.sul.stanford.edu/models/resources/image',
                       externalIdentifier: 'nx288wh8889_1',
                       label: 'Image 1',
                       version: 1,
                       structural: { contains: [{ type: 'https://cocina.sul.stanford.edu/models/file',
                                                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/1',
                                                  label: 'test.tif',
                                                  filename: 'test.tif',
                                                  version: 1,
                                                  use: 'master-role',
                                                  hasMessageDigests: [],
                                                  access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                                                  administrative: { publish: false, sdrPreserve: false, shelve: false } }] } }],
          hasMemberOrders: [],
          isMemberOf: [] }
      end

      it 'generates role attributes for structural metadata' do
        expect(result.to_h).to eq expected
      end
    end

    context 'when no objects are passed in' do
      let(:objects) { [] }

      let(:object_type) { Cocina::Models::ObjectType.object }

      it 'generates structural metadata even when no objects are passed in' do
        expect(result.to_h).to eq({ contains: [], hasMemberOrders: [], isMemberOf: [] })
      end
    end
  end
end
