# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Assembly::ContentMetadata do
  TEST_INPUT_DIR = File.join(__dir__, '../../../fixtures/content_metadata')
  TEST_TIF_INPUT_FILE = File.join(TEST_INPUT_DIR, 'test.tif')
  TEST_TIF_INPUT_FILE2 = File.join(TEST_INPUT_DIR, 'test2.tif')
  TEST_JP2_INPUT_FILE = File.join(TEST_INPUT_DIR, 'test.jp2')
  TEST_JP2_INPUT_FILE2 = File.join(TEST_INPUT_DIR, 'test2.jp2')
  TEST_SVG_INPUT_FILE  = File.join(TEST_INPUT_DIR, 'test.svg')
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
      context 'when using a single tif and jp2 with add_exif: true' do
        it 'generates valid content metadata with exif, adding file attributes' do
          objects = [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE)]
          result = described_class.create_content_metadata(druid: TEST_DRUID, add_exif: true, add_file_attributes: true, objects: objects)
          expect(result.class).to be String
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource').length).to eq 2
          expect(xml.xpath('//resource/file').length).to eq 2
          expect(xml.xpath('//resource/file/checksum').length).to eq 4
          expect(xml.xpath('//resource/file/checksum')[0].text).to eq('8d11fab63089a24c8b17063d29a4b0eac359fb41')
          expect(xml.xpath('//resource/file/checksum')[1].text).to eq('a2400500acf21e43f5440d93be894101')
          expect(xml.xpath('//resource/file/checksum')[2].text).to eq('b965b5787e0100ec2d43733144120feab327e88c')
          expect(xml.xpath('//resource/file/checksum')[3].text).to eq('4eb54050d374291ece622d45e84f014d')
          expect(xml.xpath('//label').length).to eq 2
          expect(xml.xpath('//label')[0].text).to match(/Image 1/)
          expect(xml.xpath('//label')[1].text).to match(/Image 2/)
          expect(xml.xpath('//resource')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource')[1].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource/file')[0].attributes['size'].value).to eq('63542')
          expect(xml.xpath('//resource/file')[0].attributes['mimetype'].value).to eq('image/tiff')
          expect(xml.xpath('//resource/file')[0].attributes['publish'].value).to eq('no')
          expect(xml.xpath('//resource/file')[0].attributes['preserve'].value).to eq('yes')
          expect(xml.xpath('//resource/file')[0].attributes['shelve'].value).to eq('no')
          expect(xml.xpath('//resource/file/imageData')[0].attributes['width'].value).to eq('100')
          expect(xml.xpath('//resource/file/imageData')[0].attributes['height'].value).to eq('100')
          expect(xml.xpath('//resource/file')[1].attributes['size'].value).to eq('306')
          expect(xml.xpath('//resource/file')[1].attributes['mimetype'].value).to eq('image/jp2')
          expect(xml.xpath('//resource/file')[1].attributes['publish'].value).to eq('yes')
          expect(xml.xpath('//resource/file')[1].attributes['preserve'].value).to eq('no')
          expect(xml.xpath('//resource/file')[1].attributes['shelve'].value).to eq('yes')
          expect(xml.xpath('//resource/file/imageData')[1].attributes['width'].value).to eq('100')
          expect(xml.xpath('//resource/file/imageData')[1].attributes['height'].value).to eq('100')
        end

        it 'generates valid content metadata, overriding file labels' do
          objects = [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE, label: 'Sample tif label!'), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE, label: 'Sample jp2 label!')]
          result = described_class.create_content_metadata(druid: TEST_DRUID, add_exif: true, add_file_attributes: true, objects: objects)
          expect(result.class).to be String
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource').length).to eq 2
          expect(xml.xpath('//resource/file').length).to eq 2
          expect(xml.xpath('//resource/file/checksum').length).to eq 4
          expect(xml.xpath('//resource/file/checksum')[0].text).to eq('8d11fab63089a24c8b17063d29a4b0eac359fb41')
          expect(xml.xpath('//resource/file/checksum')[1].text).to eq('a2400500acf21e43f5440d93be894101')
          expect(xml.xpath('//resource/file/checksum')[2].text).to eq('b965b5787e0100ec2d43733144120feab327e88c')
          expect(xml.xpath('//resource/file/checksum')[3].text).to eq('4eb54050d374291ece622d45e84f014d')
          expect(xml.xpath('//label').length).to eq 2
          expect(xml.xpath('//label')[0].text).to match(/Sample tif label!/)
          expect(xml.xpath('//label')[1].text).to match(/Sample jp2 label!/)
          expect(xml.xpath('//resource')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource')[1].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource/file')[0].attributes['size'].value).to eq('63542')
          expect(xml.xpath('//resource/file')[0].attributes['mimetype'].value).to eq('image/tiff')
          expect(xml.xpath('//resource/file')[0].attributes['publish'].value).to eq('no')
          expect(xml.xpath('//resource/file')[0].attributes['preserve'].value).to eq('yes')
          expect(xml.xpath('//resource/file')[0].attributes['shelve'].value).to eq('no')
          expect(xml.xpath('//resource/file/imageData')[0].attributes['width'].value).to eq('100')
          expect(xml.xpath('//resource/file/imageData')[0].attributes['height'].value).to eq('100')
          expect(xml.xpath('//resource/file')[1].attributes['size'].value).to eq('306')
          expect(xml.xpath('//resource/file')[1].attributes['mimetype'].value).to eq('image/jp2')
          expect(xml.xpath('//resource/file')[1].attributes['publish'].value).to eq('yes')
          expect(xml.xpath('//resource/file')[1].attributes['preserve'].value).to eq('no')
          expect(xml.xpath('//resource/file')[1].attributes['shelve'].value).to eq('yes')
          expect(xml.xpath('//resource/file/imageData')[1].attributes['width'].value).to eq('100')
          expect(xml.xpath('//resource/file/imageData')[1].attributes['height'].value).to eq('100')
        end
      end

      context 'when using a single tif and jp2 with add_exif: false' do
        it 'generates valid content metadata adding specific file attributes for 2 objects, and defaults for 1 object' do
          obj1 = Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE)
          obj2 = Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE)
          obj3 = Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE2)
          obj1.file_attributes = { publish: 'no', preserve: 'no', shelve: 'no' }
          obj2.file_attributes = { publish: 'yes', preserve: 'yes', shelve: 'yes' }
          objects = [obj1, obj2, obj3]
          result = described_class.create_content_metadata(druid: TEST_DRUID, add_exif: false, add_file_attributes: true, objects: objects)
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
          objects = [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE, label: 'Sample tif label!'), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE, label: '')]
          result = described_class.create_content_metadata(druid: TEST_DRUID, auto_labels: false, add_file_attributes: true, objects: objects)
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
          objects = [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE)]
          result = described_class.create_content_metadata(druid: TEST_DRUID, add_file_attributes: true,
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
          objects = [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE)]
          result = described_class.create_content_metadata(druid: TEST_DRUID, add_file_attributes: true,
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

      context 'when using two tifs and two associated jp2s using bundle=filename' do
        it 'generates valid content metadata and no exif data' do
          objects = [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE), Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE2), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE2)]
          result = described_class.create_content_metadata(druid: TEST_DRUID, bundle: :filename, objects: objects)
          expect(result.class).to be String
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource').length).to eq 2
          expect(xml.xpath('//resource/file').length).to eq 4
          expect(xml.xpath("//resource[@sequence='1']/file")[0].attributes['id'].value).to eq('test.tif')
          expect(xml.xpath("//resource[@sequence='1']/file")[1].attributes['id'].value).to eq('test.jp2')
          expect(xml.xpath("//resource[@sequence='2']/file")[0].attributes['id'].value).to eq('test2.tif')
          expect(xml.xpath("//resource[@sequence='2']/file")[1].attributes['id'].value).to eq('test2.jp2')
          expect(xml.xpath('//label').length).to eq 2
          expect(xml.xpath('//resource/file/imageData').length).to eq 0
          (0..1).each do |i|
            expect(xml.xpath("//resource[@sequence='#{i + 1}']/file").length).to eq 2
            expect(xml.xpath('//label')[i].text).to eq("Image #{i + 1}")
            expect(xml.xpath('//resource')[i].attributes['type'].value).to eq('image')
          end
        end
      end

      context 'when using two tifs and two associated jp2s using bundle=default' do
        it 'generates valid content metadata and no exif data' do
          objects = [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE), Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE2), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE2)]
          result = described_class.create_content_metadata(druid: TEST_DRUID, bundle: :default, objects: objects)
          expect(result.class).to be String
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource').length).to eq 4
          expect(xml.xpath('//resource/file').length).to eq 4
          expect(xml.xpath('//resource/file')[0].attributes['id'].value).to eq('test.tif')
          expect(xml.xpath('//resource/file')[1].attributes['id'].value).to eq('test.jp2')
          expect(xml.xpath('//resource/file')[2].attributes['id'].value).to eq('test2.tif')
          expect(xml.xpath('//resource/file')[3].attributes['id'].value).to eq('test2.jp2')
          expect(xml.xpath('//label').length).to eq 4
          expect(xml.xpath('//resource/file/imageData').length).to eq 0
          (0..3).each do |i|
            expect(xml.xpath("//resource[@sequence='#{i + 1}']/file").length).to eq 1
            expect(xml.xpath('//label')[i].text).to eq("Image #{i + 1}")
            expect(xml.xpath('//resource')[i].attributes['type'].value).to eq('image')
          end
        end
      end

      context 'when using two tifs and two associated jp2s using bundle=default' do
        it 'generates valid content metadata and no exif data, preserving full paths' do
          objects = [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE), Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE2), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE2)]
          result = described_class.create_content_metadata(druid: TEST_DRUID, bundle: :default, objects: objects, preserve_common_paths: true)
          expect(result.class).to be String
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource').length).to eq 4
          expect(xml.xpath('//resource/file').length).to eq 4
          expect(xml.xpath("//resource[@sequence='1']/file")[0].attributes['id'].value).to eq(TEST_TIF_INPUT_FILE)
          expect(xml.xpath("//resource[@sequence='2']/file")[0].attributes['id'].value).to eq(TEST_JP2_INPUT_FILE)
          expect(xml.xpath("//resource[@sequence='3']/file")[0].attributes['id'].value).to eq(TEST_TIF_INPUT_FILE2)
          expect(xml.xpath("//resource[@sequence='4']/file")[0].attributes['id'].value).to eq(TEST_JP2_INPUT_FILE2)
          expect(xml.xpath('//label').length).to eq 4
          expect(xml.xpath('//resource/file/imageData').length).to eq 0
          (0..3).each do |i|
            expect(xml.xpath("//resource[@sequence='#{i + 1}']/file").length).to eq 1
            expect(xml.xpath('//label')[i].text).to eq("Image #{i + 1}")
            expect(xml.xpath('//resource')[i].attributes['type'].value).to eq('image')
          end
        end
      end

      context 'when using bundle=prebundled' do
        it 'generates valid content metadata for images and associated text files and no exif data' do
          files = [[TEST_RES1_TIF1, TEST_RES1_JP1, TEST_RES1_TIF2, TEST_RES1_JP2, TEST_RES1_TEI, TEST_RES1_TEXT, TEST_RES1_PDF], [TEST_RES2_TIF1, TEST_RES2_JP1, TEST_RES2_TIF2, TEST_RES2_JP2, TEST_RES2_TEI, TEST_RES2_TEXT],
                   [TEST_RES3_TIF1, TEST_RES3_JP1, TEST_RES3_TEI]]
          objects = files.collect { |resource| resource.collect { |file| Assembly::ObjectFile.new(file) } }
          result = described_class.create_content_metadata(druid: TEST_DRUID, bundle: :prebundled, style: :simple_image, objects: objects)
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

      context 'when using a single svg with add_exif: true' do
        subject(:result) { described_class.create_content_metadata(druid: TEST_DRUID, add_exif: true, auto_labels: false, add_file_attributes: true, objects: objects) }

        let(:objects) { [Assembly::ObjectFile.new(TEST_SVG_INPUT_FILE)] }

        it 'generates no imageData node' do
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource/file').length).to eq 1
          expect(xml.xpath('//resource/file')[0]['mimetype']).to eq 'image/svg+xml'
          expect(xml.xpath('//resource/file')[0]['publish']).to eq('no')
          expect(xml.xpath('//resource/file')[0]['preserve']).to eq('yes')
          expect(xml.xpath('//resource/file')[0]['shelve']).to eq('no')
          expect(xml.xpath("//resource[@sequence='1']/file").length).to eq 1
          expect(xml.xpath('//imageData')).not_to be_present
          expect(xml.xpath('//resource')[0].attributes['type'].value).to eq('image')
        end
      end
    end

    context 'when style=webarchive-seed' do
      context 'when using a jp2' do
        it 'generates valid content metadata with exif, adding file attributes' do
          objects = [Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE)]
          result = described_class.create_content_metadata(style: :'webarchive-seed', druid: TEST_DRUID, add_exif: true, add_file_attributes: true, objects: objects)
          expect(result.class).to be String
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('webarchive-seed')
          expect(xml.xpath('//bookData').length).to eq 0
          expect(xml.xpath('//resource').length).to eq 1
          expect(xml.xpath('//resource/file').length).to eq 1
          expect(xml.xpath('//resource/file/checksum').length).to eq 2
          expect(xml.xpath('//resource/file/checksum')[0].text).to eq('b965b5787e0100ec2d43733144120feab327e88c')
          expect(xml.xpath('//resource/file/checksum')[1].text).to eq('4eb54050d374291ece622d45e84f014d')
          expect(xml.xpath('//label').length).to eq 1
          expect(xml.xpath('//label')[0].text).to match(/Image 1/)
          expect(xml.xpath('//resource')[0].attributes['type'].value).to eq('image')
          expect(xml.xpath('//resource/file')[0].attributes['size'].value).to eq('306')
          expect(xml.xpath('//resource/file')[0].attributes['mimetype'].value).to eq('image/jp2')
          expect(xml.xpath('//resource/file')[0].attributes['publish'].value).to eq('yes')
          expect(xml.xpath('//resource/file')[0].attributes['preserve'].value).to eq('no')
          expect(xml.xpath('//resource/file')[0].attributes['shelve'].value).to eq('yes')
          expect(xml.xpath('//resource/file/imageData')[0].attributes['width'].value).to eq('100')
          expect(xml.xpath('//resource/file/imageData')[0].attributes['height'].value).to eq('100')
        end
      end
    end

    context 'when style=map' do
      context 'when using a single tif and jp2' do
        it 'generates valid content metadata with overriding file attributes, including a default value, and no exif data' do
          objects = [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE)]
          result = described_class.create_content_metadata(style: :map,
                                                           druid: TEST_DRUID,
                                                           add_file_attributes: true,
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
      context 'when using two tifs, two associated jp2s, one pdf and two txts using bundle=filename' do
        let(:objects) do
          [
            Assembly::ObjectFile.new(TEST_RES1_TIF1),
            Assembly::ObjectFile.new(TEST_RES1_TIF2),
            Assembly::ObjectFile.new(TEST_RES1_JP2),
            Assembly::ObjectFile.new(TEST_RES1_PDF),
            Assembly::ObjectFile.new(TEST_RES1_JP1),
            Assembly::ObjectFile.new(TEST_RES1_TEXT),
            Assembly::ObjectFile.new(TEST_RES1_TEI)
          ]
        end

        it 'generates valid content metadata and no exif data and no root xml node' do
          result = described_class.create_content_metadata(druid: TEST_DRUID, style: :simple_book, bundle: :filename, objects: objects, include_root_xml: false)
          expect(result.class).to be String
          expect(result.include?('<?xml')).to be false
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('book')
          expect(xml.xpath('//contentMetadata')[0].attributes['objectId'].value).to eq(TEST_DRUID.to_s)
          expect(xml.xpath('//bookData')[0].attributes['readingOrder'].value).to eq('ltr')
          expect(xml.xpath('//resource').length).to eq 5
          expect(xml.xpath('//resource/file').length).to eq 7
          expect(xml.xpath("//resource[@sequence='1']/file")[0].attributes['id'].value).to eq('res1_image1.tif')
          expect(xml.xpath("//resource[@sequence='1']/file")[1].attributes['id'].value).to eq('res1_image1.jp2')
          expect(xml.xpath("//resource[@sequence='2']/file")[0].attributes['id'].value).to eq('res1_image2.tif')
          expect(xml.xpath("//resource[@sequence='2']/file")[1].attributes['id'].value).to eq('res1_image2.jp2')
          expect(xml.xpath("//resource[@sequence='3']/file")[0].attributes['id'].value).to eq('res1_transcript.pdf')
          expect(xml.xpath("//resource[@sequence='4']/file")[0].attributes['id'].value).to eq('res1_textfile.txt')
          expect(xml.xpath("//resource[@sequence='5']/file")[0].attributes['id'].value).to eq('res1_teifile.txt')
          expect(xml.xpath('//label').length).to eq 5
          expect(xml.xpath('//resource/file/imageData').length).to eq 0
          (0..1).each do |i|
            expect(xml.xpath("//resource[@sequence='#{i + 1}']/file").length).to eq 2
            expect(xml.xpath('//label')[i].text).to eq("Page #{i + 1}")
            expect(xml.xpath('//resource')[i].attributes['type'].value).to eq('page')
          end
          expect(xml.xpath("//resource[@sequence='3']/file").length).to eq 1
          expect(xml.xpath('//label')[2].text).to eq('Object 1')
          expect(xml.xpath('//resource')[2].attributes['type'].value).to eq('object')
          expect(xml.xpath("//resource[@sequence='4']/file").length).to eq 1
          expect(xml.xpath('//label')[3].text).to eq('Object 2')
          expect(xml.xpath('//resource')[3].attributes['type'].value).to eq('object')
          expect(xml.xpath("//resource[@sequence='5']/file").length).to eq 1
          expect(xml.xpath('//label')[4].text).to eq('Object 3')
          expect(xml.xpath('//resource')[4].attributes['type'].value).to eq('object')
        end
      end

      context "when item has a 'druid:' prefix and specified book order. Using two tifs, two associated jp2s, one pdf and two txts using bundle=filename" do
        let(:objects) do
          [
            Assembly::ObjectFile.new(TEST_RES1_TIF1),
            Assembly::ObjectFile.new(TEST_RES1_TIF2),
            Assembly::ObjectFile.new(TEST_RES1_JP2),
            Assembly::ObjectFile.new(TEST_RES1_PDF),
            Assembly::ObjectFile.new(TEST_RES1_JP1),
            Assembly::ObjectFile.new(TEST_RES1_TEXT),
            Assembly::ObjectFile.new(TEST_RES1_TEI)
          ]
        end

        it 'generates valid content metadata' do
          test_druid = "druid:#{TEST_DRUID}"
          result = described_class.create_content_metadata(druid: test_druid, bundle: :filename, objects: objects, style: :simple_book, reading_order: 'rtl')
          expect(result.class).to be String
          expect(result.include?('<?xml')).to be true
          xml = Nokogiri::XML(result)
          expect(xml.errors.size).to eq 0
          expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('book')
          expect(xml.xpath('//contentMetadata')[0].attributes['objectId'].value).to eq(test_druid)
          expect(xml.xpath('//bookData')[0].attributes['readingOrder'].value).to eq('rtl')
          expect(test_druid).to eq("druid:#{TEST_DRUID}")
          expect(xml.xpath('//resource').length).to eq 5
          expect(xml.xpath('//resource/file').length).to be 7

          expect(xml.xpath("//resource[@sequence='1']/file")[0].attributes['id'].value).to eq('res1_image1.tif')
          expect(xml.xpath("//resource[@sequence='1']/file")[1].attributes['id'].value).to eq('res1_image1.jp2')
          expect(xml.xpath("//resource[@sequence='2']/file")[0].attributes['id'].value).to eq('res1_image2.tif')
          expect(xml.xpath("//resource[@sequence='2']/file")[1].attributes['id'].value).to eq('res1_image2.jp2')
          expect(xml.xpath("//resource[@sequence='3']/file")[0].attributes['id'].value).to eq('res1_transcript.pdf')
          expect(xml.xpath("//resource[@sequence='4']/file")[0].attributes['id'].value).to eq('res1_textfile.txt')
          expect(xml.xpath("//resource[@sequence='5']/file")[0].attributes['id'].value).to eq('res1_teifile.txt')
          expect(xml.xpath('//label').length).to eq 5
          expect(xml.xpath('//resource/file/imageData').length).to eq 0
          (0..1).each do |i|
            expect(xml.xpath("//resource[@sequence='#{i + 1}']/file").length).to eq 2
            expect(xml.xpath('//label')[i].text).to eq("Page #{i + 1}")
            expect(xml.xpath('//resource')[i].attributes['type'].value).to eq('page')
          end
          expect(xml.xpath("//resource[@sequence='3']/file").length).to eq 1
          expect(xml.xpath('//label')[2].text).to eq('Object 1')
          expect(xml.xpath('//resource')[2].attributes['type'].value).to eq('object')
        end
      end

      context 'with invalid reading order' do
        subject(:result) { described_class.create_content_metadata(druid: "druid:#{TEST_DRUID}", bundle: :filename, objects: [], style: :simple_book, reading_order: 'bogus') }

        it 'throws an error' do
          expect { result }.to raise_error(Dry::Struct::Error)
        end
      end

      context 'when using two tifs' do
        it 'generates valid content metadata for two tifs of style=simple_book' do
          objects = [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE), Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE2)]
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
            expect(xml.xpath('//resource/file')[i].attributes['publish']).to be_nil
            expect(xml.xpath('//resource/file')[i].attributes['preserve']).to be_nil
            expect(xml.xpath('//resource/file')[i].attributes['shelve']).to be_nil
          end
          expect(xml.xpath('//resource')[0].attributes['type'].value).to eq('page')
          expect(xml.xpath('//resource')[1].attributes['type'].value).to eq('page')
        end
      end
    end

    context 'when style=file' do
      context 'when using two tifs and two associated jp2s' do
        it 'generates valid content metadata using specific content metadata paths' do
          objects = [Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE), Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE2), Assembly::ObjectFile.new(TEST_JP2_INPUT_FILE2)]
          objects[0].relative_path = 'input/test.tif'
          objects[1].relative_path = 'input/test.jp2'
          objects[2].relative_path = 'input/test2.tif'
          objects[3].relative_path = 'input/test2.jp2'
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

    context 'when using style=document' do
      let(:objects) do
        [Assembly::ObjectFile.new(TEST_PDF_FILE)]
      end

      let(:style) { :document }

      it 'generates valid content metadata' do
        expect(xml.errors.size).to eq 0
        expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('document')
        expect(xml.xpath('//bookData').length).to eq 0
        expect(xml.xpath('//resource').length).to eq 1
        expect(xml.xpath('//resource/file').length).to eq 1
        expect(xml.xpath('//label').length).to eq 1
        expect(xml.xpath('//label')[0].text).to match(/Document 1/)
        expect(xml.xpath('//resource/file/imageData').length).to eq 0
        file = xml.xpath('//resource/file').first
        expect(file.attributes['size']).to be_nil
        expect(file.attributes['mimetype']).to be_nil
        expect(file.attributes['publish']).to be_nil
        expect(file.attributes['preserve']).to be_nil
        expect(file.attributes['shelve']).to be_nil
        expect(xml.xpath('//resource')[0].attributes['type'].value).to eq('document')
      end
    end

    context 'when using user supplied checksums for two tifs and style=simple_book' do
      it 'generates valid content metadata with no exif' do
        obj1 = Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE)
        obj1.provider_md5 = '123456789'
        obj1.provider_sha1 = 'abcdefgh'
        obj2 = Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE2)
        obj2.provider_md5 = 'qwerty'
        objects = [obj1, obj2]
        result = described_class.create_content_metadata(druid: TEST_DRUID, style: :simple_book, objects: objects)
        expect(result.class).to be String
        xml = Nokogiri::XML(result)
        expect(xml.errors.size).to eq 0
        expect(xml.xpath('//contentMetadata')[0].attributes['type'].value).to eq('book')
        expect(xml.xpath('//resource').length).to eq 2
        expect(xml.xpath('//resource/file').length).to eq 2
        expect(xml.xpath('//resource/file/checksum').length).to eq 3
        expect(xml.xpath('//label').length).to eq 2
        expect(xml.xpath('//label')[0].text).to match(/Page 1/)
        expect(xml.xpath('//label')[1].text).to match(/Page 2/)
        expect(xml.xpath('//resource/file/imageData').length).to eq 0
        expect(xml.xpath('//resource/file/checksum')[0].text).to eq('abcdefgh')
        expect(xml.xpath('//resource/file/checksum')[1].text).to eq('123456789')
        expect(xml.xpath('//resource/file/checksum')[2].text).to eq('qwerty')
        (0..1).each do |i|
          expect(xml.xpath('//resource/file')[i].attributes['size']).to be_nil
          expect(xml.xpath('//resource/file')[i].attributes['mimetype']).to be_nil
          expect(xml.xpath('//resource/file')[i].attributes['publish']).to be_nil
          expect(xml.xpath('//resource/file')[i].attributes['preserve']).to be_nil
          expect(xml.xpath('//resource/file')[i].attributes['shelve']).to be_nil
        end
        expect(xml.xpath('//resource')[0].attributes['type'].value).to eq('page')
        expect(xml.xpath('//resource')[1].attributes['type'].value).to eq('page')
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
        [Assembly::ObjectFile.new(TEST_OBJ_FILE),
         Assembly::ObjectFile.new(TEST_PLY_FILE),
         Assembly::ObjectFile.new(TEST_TIF_INPUT_FILE),
         Assembly::ObjectFile.new(TEST_PDF_FILE)]
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
        objects = [obj1]
        result = described_class.create_content_metadata(druid: TEST_DRUID, add_exif: false, add_file_attributes: true, objects: objects)
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
      subject(:result) { described_class.create_content_metadata(druid: TEST_DRUID, bundle: :prebundled, style: style, objects: objects) }

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
      subject(:result) { described_class.create_content_metadata(druid: TEST_DRUID, bundle: :prebundled, style: style, objects: objects) }

      let(:objects) { [] }

      let(:style) { :borked }

      it 'generates an error message' do
        expect { result }.to raise_error 'Supplied style (borked) not valid'
      end
    end
  end
end
