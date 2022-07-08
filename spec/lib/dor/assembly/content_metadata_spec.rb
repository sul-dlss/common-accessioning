# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Assembly::ContentMetadata do
  TEST_INPUT_DIR = File.join(__dir__, '../../../fixtures/content_metadata')
  TEST_TIF_INPUT_FILE = File.join(TEST_INPUT_DIR, 'test.tif')
  TEST_TIF_INPUT_FILE2 = File.join(TEST_INPUT_DIR, 'test2.tif')
  TEST_JP2_INPUT_FILE = File.join(TEST_INPUT_DIR, 'test.jp2')
  TEST_JP2_INPUT_FILE2 = File.join(TEST_INPUT_DIR, 'test2.jp2')

  TEST_RES1_TIF1 = File.join(TEST_INPUT_DIR, 'res1_image1.tif')
  TEST_RES1_TIF2 = File.join(TEST_INPUT_DIR, 'res1_image2.tif')
  TEST_RES1_TEI = File.join(TEST_INPUT_DIR, 'res1_teifile.txt')
  TEST_RES1_TEXT = File.join(TEST_INPUT_DIR, 'res1_textfile.txt')
  TEST_RES1_PDF = File.join(TEST_INPUT_DIR, 'res1_transcript.pdf')
  TEST_RES1_JP1 = File.join(TEST_INPUT_DIR, 'res1_image1.jp2')
  TEST_RES1_JP2 = File.join(TEST_INPUT_DIR, 'res1_image2.jp2')

  TEST_RES2_TIF1 = File.join(TEST_INPUT_DIR, 'res2_image1.tif')
  TEST_RES2_JP1 = File.join(TEST_INPUT_DIR, 'res2_image1.jp2')
  TEST_RES2_TIF2 = File.join(TEST_INPUT_DIR, 'res2_image2.tif')
  TEST_RES2_JP2 = File.join(TEST_INPUT_DIR, 'res2_image2.jp2')
  TEST_RES2_TEI = File.join(TEST_INPUT_DIR, 'res2_teifile.txt')
  TEST_RES2_TEXT = File.join(TEST_INPUT_DIR, 'res2_textfile.txt')

  TEST_RES3_TIF1 = File.join(TEST_INPUT_DIR, 'res3_image1.tif')
  TEST_RES3_JP1 = File.join(TEST_INPUT_DIR, 'res3_image1.jp2')
  TEST_RES3_TEI = File.join(TEST_INPUT_DIR, 'res3_teifile.txt')

  TEST_OBJ_FILE = File.join(TEST_INPUT_DIR, 'someobject.obj')
  TEST_PLY_FILE = File.join(TEST_INPUT_DIR, 'someobject.ply')

  TEST_PDF_FILE = File.join(TEST_INPUT_DIR, 'test.pdf')

  TEST_DRUID = 'nx288wh8889'

  describe '#create_content_metadata' do
    subject(:result) { described_class.create_content_metadata(druid: TEST_DRUID, style: style, objects: objects) }

    let(:xml) { Nokogiri::XML(result) }

    context 'when style=simple_image' do
      context 'when using a single tif and jp2' do
        it 'generates valid content metadata adding specific file attributes for 2 objects, and defaults for 1 object' do
          obj1 = Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE)
          obj2 = Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE)
          obj3 = Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE2)
          obj1.file_attributes = { publish: 'no', preserve: 'no', shelve: 'no' }
          obj2.file_attributes = { publish: 'yes', preserve: 'yes', shelve: 'yes' }
          objects = [[obj1], [obj2], [obj3]]
          result = described_class.create_content_metadata(druid: TEST_DRUID, objects: objects)
          expect(result.class).to be String
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource').length).to eq 3
          expect(xml.xpath('//resource/file').length).to eq 3
          expect(xml.xpath('//resource/file/checksum').length).to eq 0
          expect(xml.xpath('//resource/file/imageData').length).to eq 0
          expect(xml.xpath('//label').length).to eq 3
          expect(xml.xpath('//label')[0].text).to match(/Image 1/)
          expect(xml.xpath('//label')[1].text).to match(/Image 2/)
          expect(xml.xpath('//label')[2].text).to match(/Image 3/)
          expect(xml.xpath('//resource')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource')[1].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource')[2].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource/file')[0].attributes['publish'].value).to eq('no') # specificially set in object
          expect(xml.xpath('//resource/file')[0].attributes['preserve'].value).to eq('no') # specificially set in object
          expect(xml.xpath('//resource/file')[0].attributes['shelve'].value).to eq('no') # specificially set in object
          expect(xml.xpath('//resource/file')[1].attributes['publish'].value).to eq('yes') # specificially set in object
          expect(xml.xpath('//resource/file')[1].attributes['preserve'].value).to eq('yes') # specificially set in object
          expect(xml.xpath('//resource/file')[1].attributes['shelve'].value).to eq('yes')  # specificially set in object
          expect(xml.xpath('//resource/file')[2].attributes['publish'].value).to eq('yes') # defaults by mimetype
          expect(xml.xpath('//resource/file')[2].attributes['preserve'].value).to eq('no') # defaults by mimetype
          expect(xml.xpath('//resource/file')[2].attributes['shelve'].value).to eq('yes') # defaults by mimetype
        end
      end

      context 'when using a single tif and jp2' do
        it 'generates valid content metadata with exif, overriding file labels for one, and skipping auto labels for the others or for where the label is set but is blank' do
          objects = [[Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE, label: 'Sample tif label!')], [Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE)], [Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE, label: '')]]
          result = described_class.create_content_metadata(druid: TEST_DRUID, auto_labels: false, objects: objects)
          expect(result.class).to be String
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource').length).to eq 3
          expect(xml.xpath('//resource/file').length).to eq 3
          expect(xml.xpath('//label').length).to eq 1
          expect(xml.xpath('//label')[0].text).to match(/Sample tif label!/)
        end
      end

      context 'when using a single tif and jp2' do
        it 'generates valid content metadata with overriding file attributes and no exif data' do
          objects = [[Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE)], [Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE)]]
          result = described_class.create_content_metadata(druid: TEST_DRUID,
                                                           file_attributes: { 'image/tiff' => { publish: 'no', preserve: 'no', shelve: 'no' }, 'image/jp2' => { publish: 'yes', preserve: 'yes', shelve: 'yes' } }, objects: objects)
          expect(result.class).to be String
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource').length).to eq 2
          expect(xml.xpath('//resource/file').length).to eq 2
          expect(xml.xpath('//label').length).to eq 2
          expect(xml.xpath('//resource/file/imageData').length).to eq 0
          expect(xml.xpath('//label')[0].text).to match(/Image 1/)
          expect(xml.xpath('//label')[1].text).to match(/Image 2/)
          expect(xml.xpath('//resource')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource')[1].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource/file')[0].attributes['size']).to be_nil
          expect(xml.xpath('//resource/file')[0].attributes['mimetype']).to be_nil
          expect(xml.xpath('//resource/file')[0].attributes['role']).to be_nil
          expect(xml.xpath('//resource/file')[0].attributes['publish'].value).to eq('no')
          expect(xml.xpath('//resource/file')[0].attributes['preserve'].value).to eq('no')
          expect(xml.xpath('//resource/file')[0].attributes['shelve'].value).to eq('no')
          expect(xml.xpath('//resource/file')[1].attributes['size']).to be_nil
          expect(xml.xpath('//resource/file')[1].attributes['mimetype']).to be_nil
          expect(xml.xpath('//resource/file')[1].attributes['role']).to be_nil
          expect(xml.xpath('//resource/file')[1].attributes['publish'].value).to eq('yes')
          expect(xml.xpath('//resource/file')[1].attributes['preserve'].value).to eq('yes')
          expect(xml.xpath('//resource/file')[1].attributes['shelve'].value).to eq('yes')
        end
      end

      context 'when using a single tif and jp2' do
        it 'generates valid content metadata with overriding file attributes, including a default value, and no exif data' do
          objects = [[Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE)], [Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE)]]
          result = described_class.create_content_metadata(druid: TEST_DRUID,
                                                           file_attributes: { 'default' => { publish: 'yes', preserve: 'no', shelve: 'no' }, 'image/jp2' => { publish: 'yes', preserve: 'yes', shelve: 'yes' } }, objects: objects)
          expect(result.class).to be String
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource/file').length).to eq 2
          expect(xml.xpath('//resource/file')[0].attributes['mimetype']).to be_nil
          expect(xml.xpath('//resource/file')[0].attributes['publish'].value).to eq('yes')
          expect(xml.xpath('//resource/file')[0].attributes['preserve'].value).to eq('no')
          expect(xml.xpath('//resource/file')[0].attributes['shelve'].value).to eq('no')
          expect(xml.xpath('//resource/file')[1].attributes['mimetype']).to be_nil
          expect(xml.xpath('//resource/file')[1].attributes['publish'].value).to eq('yes')
          expect(xml.xpath('//resource/file')[1].attributes['preserve'].value).to eq('yes')
          expect(xml.xpath('//resource/file')[1].attributes['shelve'].value).to eq('yes')
          (0..1).each do |i|
            expect(xml.xpath("//resource[@sequence='#{i + 1}']/file").length).to eq 1
            expect(xml.xpath('//label')[i].text).to eq("Image #{i + 1}")
            expect(xml.xpath('//resource')[i].attributes['type'].value).to eq('image')
          end
        end
      end

      context 'when providing multiple files per resource' do
        it 'generates valid content metadata for images and associated text files and no exif data' do
          files = [[TEST_RES1_TIF1, TEST_RES1_JP1, TEST_RES1_TIF2, TEST_RES1_JP2, TEST_RES1_TEI, TEST_RES1_TEXT, TEST_RES1_PDF], [TEST_RES2_TIF1, TEST_RES2_JP1, TEST_RES2_TIF2, TEST_RES2_JP2, TEST_RES2_TEI, TEST_RES2_TEXT],
                   [TEST_RES3_TIF1, TEST_RES3_JP1, TEST_RES3_TEI]]
          objects = files.collect { |resource| resource.collect { |file| Assembly::ObjectFile.new(file) } }
          result = described_class.create_content_metadata(druid: TEST_DRUID, style: :simple_image, objects: objects)
          expect(result.class).to be String
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource').length).to eq 3
          expect(xml.xpath('//resource/file').length).to eq 16
          expect(xml.xpath("//resource[@sequence='1']/file")[0].attributes['id'].value).to eq('res1_image1.tif')
          expect(xml.xpath("//resource[@sequence='1']/file")[1].attributes['id'].value).to eq('res1_image1.jp2')
          expect(xml.xpath("//resource[@sequence='1']/file")[2].attributes['id'].value).to eq('res1_image2.tif')
          expect(xml.xpath("//resource[@sequence='1']/file")[3].attributes['id'].value).to eq('res1_image2.jp2')
          expect(xml.xpath("//resource[@sequence='1']/file")[4].attributes['id'].value).to eq('res1_teifile.txt')
          expect(xml.xpath("//resource[@sequence='1']/file")[5].attributes['id'].value).to eq('res1_textfile.txt')
          expect(xml.xpath("//resource[@sequence='1']/file")[6].attributes['id'].value).to eq('res1_transcript.pdf')
          expect(xml.xpath("//resource[@sequence='1']/file").length).to be 7

          expect(xml.xpath("//resource[@sequence='2']/file")[0].attributes['id'].value).to eq('res2_image1.tif')
          expect(xml.xpath("//resource[@sequence='2']/file")[1].attributes['id'].value).to eq('res2_image1.jp2')
          expect(xml.xpath("//resource[@sequence='2']/file")[2].attributes['id'].value).to eq('res2_image2.tif')
          expect(xml.xpath("//resource[@sequence='2']/file")[3].attributes['id'].value).to eq('res2_image2.jp2')
          expect(xml.xpath("//resource[@sequence='2']/file")[4].attributes['id'].value).to eq('res2_teifile.txt')
          expect(xml.xpath("//resource[@sequence='2']/file")[5].attributes['id'].value).to eq('res2_textfile.txt')
          expect(xml.xpath("//resource[@sequence='2']/file").length).to eq 6

          expect(xml.xpath("//resource[@sequence='3']/file")[0].attributes['id'].value).to eq('res3_image1.tif')
          expect(xml.xpath("//resource[@sequence='3']/file")[1].attributes['id'].value).to eq('res3_image1.jp2')
          expect(xml.xpath("//resource[@sequence='3']/file")[2].attributes['id'].value).to eq('res3_teifile.txt')
          expect(xml.xpath("//resource[@sequence='3']/file").length).to eq 3

          expect(xml.xpath('//label').length).to eq 3
          expect(xml.xpath('//resource/file/imageData').length).to eq 0
          (0..2).each do |i|
            expect(xml.xpath('//label')[i].text).to eq("Image #{i + 1}")
            expect(xml.xpath('//resource')[i].attributes['type'].value).to eq('image')
          end
        end
      end
    end

    context 'when style=map' do
      context 'when using a single tif and jp2' do
        it 'generates valid content metadata with overriding file attributes, including a default value, and no exif data' do
          objects = [[Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE)], [Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE)]]
          result = described_class.create_content_metadata(style: :map,
                                                           druid: TEST_DRUID,
                                                           file_attributes: { 'default' => { publish: 'yes', preserve: 'no', shelve: 'no' },
                                                                              'image/jp2' => { publish: 'yes', preserve: 'yes', shelve: 'yes' } },
                                                           objects: objects)
          expect(result.class).to be String
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('map')
          expect(xml.xpath('//bookData').length).to eq 0
          expect(xml.xpath('//resource/file').length).to eq 2
          expect(xml.xpath('//resource/file')[0].attributes['mimetype']).to be_nil
          expect(xml.xpath('//resource/file')[0].attributes['publish'].value).to eq('yes')
          expect(xml.xpath('//resource/file')[0].attributes['preserve'].value).to eq('no')
          expect(xml.xpath('//resource/file')[0].attributes['shelve'].value).to eq('no')
          expect(xml.xpath('//resource/file')[1].attributes['mimetype']).to be_nil
          expect(xml.xpath('//resource/file')[1].attributes['publish'].value).to eq('yes')
          expect(xml.xpath('//resource/file')[1].attributes['preserve'].value).to eq('yes')
          expect(xml.xpath('//resource/file')[1].attributes['shelve'].value).to eq('yes')
          (0..1).each do |i|
            expect(xml.xpath("//resource[@sequence='#{i + 1}']/file").length).to eq 1
            expect(xml.xpath('//label')[i].text).to eq("Image #{i + 1}")
            expect(xml.xpath('//resource')[i].attributes['type'].value).to eq('image')
          end
        end
      end
    end

    context 'when style=simple_book' do
      context 'when using two tifs' do
        it 'generates valid content metadata for two tifs of style=simple_book' do
          objects = [[Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE)], [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE2)]]
          result = described_class.create_content_metadata(druid: TEST_DRUID, style: :simple_book, objects: objects)
          expect(result.class).to be String
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('book')
          expect(xml.xpath('//resource').length).to eq 2
          expect(xml.xpath('//resource/file').length).to eq 2
          expect(xml.xpath('//label').length).to eq 2
          expect(xml.xpath('//label')[0].text).to match(/Page 1/)
          expect(xml.xpath('//label')[1].text).to match(/Page 2/)
          expect(xml.xpath('//resource/file/imageData').length).to eq 0
          (0..1).each do |i|
            expect(xml.xpath('//resource/file')[i].attributes['size']).to be_nil
            expect(xml.xpath('//resource/file')[i].attributes['mimetype']).to be_nil
            expect(xml.xpath('//resource/file')[i].attributes['publish'].text).to eq 'no'
            expect(xml.xpath('//resource/file')[i].attributes['preserve'].text).to eq 'yes'
            expect(xml.xpath('//resource/file')[i].attributes['shelve'].text).to eq 'no'
          end

          expect(xml.xpath('//resource')[0].attributes['type'].value).to eq('page')
          expect(xml.xpath('//resource')[1].attributes['type'].value).to eq('page')
        end
      end
    end

    context 'when style=file' do
      context 'when using two tifs and two associated jp2s' do
        it 'generates valid content metadata using specific content metadata paths' do
          objects = [[Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE)], [Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE)], [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE2)], [Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE2)]]
          objects[0].first.relative_path = 'input/test.tif'
          objects[1].first.relative_path = 'input/test.jp2'
          objects[2].first.relative_path = 'input/test2.tif'
          objects[3].first.relative_path = 'input/test2.jp2'
          result = described_class.create_content_metadata(druid: TEST_DRUID, style: :file, objects: objects)
          expect(result.class).to be String
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('file')
          expect(xml.xpath('//bookData').length).to eq 0
          expect(xml.xpath('//resource').length).to eq 4
          expect(xml.xpath('//resource/file').length).to eq 4
          expect(xml.xpath('//label').length).to eq 4
          expect(xml.xpath('//resource/file')[0].attributes['id'].value).to eq('input/test.tif')
          expect(xml.xpath('//resource/file')[1].attributes['id'].value).to eq('input/test.jp2')
          expect(xml.xpath('//resource/file')[2].attributes['id'].value).to eq('input/test2.tif')
          expect(xml.xpath('//resource/file')[3].attributes['id'].value).to eq('input/test2.jp2')
          (0..3).each do |i|
            expect(xml.xpath("//resource[@sequence='#{i + 1}']/file").length).to eq 1
            expect(xml.xpath('//label')[i].text).to eq("File #{i + 1}")
            expect(xml.xpath('//resource')[i].attributes['type'].value).to eq('file')
          end
        end
      end
    end

    context 'when not all input files exist' do
      it 'does not generate valid content metadata' do
        junk_file = '/tmp/flim_flam_floom.jp2'
        expect(File.exist?(junk_file)).to be false
        objects = [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE), Assembly::ObjectFile.new(junk_file)]
        expect { described_class.create_content_metadata(druid: TEST_DRUID, objects: objects) }.to raise_error(RuntimeError, "File '#{junk_file}' not found")
      end
    end

    context 'when using a 3d object with one 3d type files and three other supporting files (where one supporting file is a non-viewable but downloadable 3d file)' do
      let(:objects) do
        [[Assembly::ObjectFile.new(TEST_OBJ_FILE)],
         [Assembly::ObjectFile.new(TEST_PLY_FILE)],
         [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE)],
         [Assembly::ObjectFile.new(TEST_PDF_FILE)]]
      end
      let(:style) { :'3d' }

      it 'generates valid content metadata' do
        expect(xml.errors.size).to eq 0
        expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('3d')
        expect(xml.xpath('//bookData').length).to eq 0
        expect(xml.xpath('//resource').length).to eq 4
        expect(xml.xpath('//resource/file').length).to eq 4
        expect(xml.xpath('//label').length).to eq 4
        expect(xml.xpath('//label')[0].text).to match(/3d 1/)
        expect(xml.xpath('//label')[1].text).to match(/File 1/)
        expect(xml.xpath('//label')[2].text).to match(/File 2/)
        expect(xml.xpath('//label')[3].text).to match(/File 3/)
        expect(xml.xpath('//resource/file/imageData').length).to eq 0
        expect(xml.xpath('//resource')[0].attributes['type'].value).to eq('3d')
        expect(xml.xpath('//resource')[1].attributes['type'].value).to eq('file')
        expect(xml.xpath('//resource')[2].attributes['type'].value).to eq('file')
        expect(xml.xpath('//resource')[3].attributes['type'].value).to eq('file')
      end
    end

    context 'when providing file attributes' do
      it 'generates role attributes for content metadata' do
        obj1 = Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE)
        obj1.file_attributes = { publish: 'no', preserve: 'no', shelve: 'no', role: 'master-role' }
        objects = [[obj1]]
        result = described_class.create_content_metadata(druid: TEST_DRUID, objects: objects)
        expect(result.class).to be String
        xml = Nokogiri::XML(result)
        expect(xml.errors.size).to eq 0
        expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('image')
        expect(xml.xpath('//resource').length).to eq 1
        expect(xml.xpath('//resource/file').length).to eq 1
        expect(xml.xpath('//resource/file').length).to eq 1
        expect(xml.xpath('//resource/file')[0].attributes['role'].value).to eq('master-role')
      end
    end

    context 'when no objects are passed in' do
      subject(:result) { described_class.create_content_metadata(druid: TEST_DRUID, style: style, objects: objects) }

      let(:objects) { [] }

      let(:style) { :file }

      it 'generates content metadata even when no objects are passed in' do
        expect(xml.errors.size).to eq 0
        expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('file')
        expect(xml.xpath('//resource').length).to eq 0
        expect(xml.xpath('//resource/file').length).to eq 0
      end
    end

    context 'when an unknown style is passed in' do
      subject(:result) { described_class.create_content_metadata(druid: TEST_DRUID, style: style, objects: objects) }

      let(:objects) { [] }

      let(:style) { :borked }

      it 'generates an error message' do
        expect { result }.to raise_error 'Supplied style (borked) not valid'
      end
    end
  end
end
