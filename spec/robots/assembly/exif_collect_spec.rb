# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::ExifCollect do
  let(:robot) { described_class.new }
  let(:druid) { 'aa222cc3333' }
  let(:type) { 'item' }
  let(:item) do
    instance_double(Dor::Assembly::Item,
                    item?: type == 'item')
  end

  before do
    allow(Dor::Assembly::Item).to receive(:new).and_return(item)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    context "when it's an item" do
      it 'collects exif' do
        expect(item).to receive(:load_content_metadata)
        expect(robot).to receive(:collect_exif_info)
        perform
      end
    end

    context "when it's a set" do
      let(:type) { 'set' }

      it 'does not collect exif' do
        expect(item).not_to receive(:load_content_metadata)
        expect(robot).not_to receive(:collect_exif_info)
        perform
      end
    end
  end

  def run_persist_xml_test; end

  describe '#set_node_type_as_image' do
    let(:ng_xml) do
      Nokogiri.XML(xml) { |conf| conf.default_xml.noblanks }
    end
    let(:xml) { '<contentMetadata><resource></resource></contentMetadata>' }

    it 'adds type="image" attributes correctly' do
      %w[contentMetadata resource].each do |tag|
        node = ng_xml.xpath("//#{tag}").first
        robot.send(:set_node_type, node, 'image')
      end
      exp = Nokogiri::XML('<contentMetadata type="image"><resource type="image">' \
                          '</resource></contentMetadata>')
      expect(ng_xml).to be_equivalent_to exp
    end
  end

  describe '#collect_exif_info' do
    subject(:result) { robot.send(:collect_exif_info, item) }

    let(:item) { Dor::Assembly::Item.new(druid: druid) }

    let(:exif) { double('result', mimetype: nil, image_width: 7, image_height: 9) }

    before do
      allow(item).to receive(:item?).and_return(true)
      allow(item).to receive(:load_content_metadata)
      allow(item).to receive(:cm).and_return(Nokogiri::XML(xml))
      allow(item).to receive(:druid).and_return('foo:999')
    end

    context 'when there are no existing mimetypes and filesizes in file nodes' do
      let(:xml) do
        <<~XML
          <contentMetadata objectId="aa111bb2222">
              <resource type="image" sequence="1" id="aa111bb2222_1">
                  <label>Image 1</label>
                  <file preserve="yes" publish="no" shelve="no" id="image111.tif">
                      <checksum type="md5">42616f9e6c1b7e7b7a71b4fa0c5ef794</checksum>
                  </file>
              </resource>
              <resource type="image" sequence="2" id="aa111bb2222_2">
                  <label>Image 2</label>
                  <file preserve="yes" publish="no" shelve="no" id="image112.tif">
                      <checksum type="md5">ac440802bd590ce0899dafecc5a5ab1b</checksum>
                      <checksum type="sha1">5c9f6dc2ca4fd3329619b54a2c6f99a08c088444</checksum>
                      <checksum type="foo">FOO</checksum>
                      <checksum type="bar">BAR</checksum>
                  </file>
              </resource>
              <resource type="image" sequence="3" id="aa111bb2222_3">
                  <label>Image 3</label>
                  <file preserve="yes" publish="no" shelve="no" id="sub/image113.tif" />
              </resource>
          </contentMetadata>
        XML
      end

      let(:druid) { 'druid:aa111bb2222' }

      before do
        allow(Assembly::ObjectFile).to receive(:new).and_return(
          double('one', mimetype: 'image/tiff', filesize: 63_468, object_type: :image, exif: exif),
          double('two', mimetype: 'image/tiff', filesize: 63_472, object_type: :image, exif: exif),
          double('three', mimetype: 'image/tiff', filesize: 63_472, object_type: :image, exif: exif)
        )
      end

      it 'persists the content with the size and mimetype' do
        expect(item).to receive(:persist_content_metadata)
        result
        expect(item.cm.root['type']).to eq 'image'

        # check that each file node now has size, mimetype
        aft_file_nodes = item.cm.xpath('//file')
        expect(aft_file_nodes.size).to eq(3)
        expect(aft_file_nodes[0].attributes['size'].value).to eq('63468')
        expect(aft_file_nodes[1].attributes['size'].value).to eq('63472')
        aft_file_nodes.each { |file_node| expect(file_node.attributes['mimetype'].value).to eq('image/tiff') }

        # check that each resource node is still type=image
        aft_res_nodes = item.cm.xpath('//resource')
        expect(aft_res_nodes.size).to eq(3)
        aft_res_nodes.each do |res_node|
          expect(res_node.attributes['type'].value).to eq('image')
        end

        # check for imageData nodes being present for each file node
        expect(item.cm.xpath('//file/imageData').size).to eq(3)
      end
    end

    context 'when there are existing mimetypes and filesizes in file nodes' do
      let(:xml) do
        <<~XML
          <contentMetadata objectId="cc333dd4444">
              <resource sequence="1" id="cc333dd4444_1">
                  <label>Image 1</label>
                  <file mimetype="crappy/mimetype" size="100" preserve="yes" publish="no" shelve="no" id="image222.tif">
                      <checksum type="md5">3d5812d6b2506ec96a6bdef5795a888b</checksum>
                  </file>
                  <file mimetype="crappy/again" size="500" preserve="yes" publish="no" shelve="no" id="image222.txt">
                      <checksum type="md5">0929b8b53d900da1ddd1603ec7f29c36</checksum>
                  </file>
              </resource>
          </contentMetadata>
        XML
      end

      let(:druid) { 'druid:cc333dd4444' }

      before do
        allow(Assembly::ObjectFile).to receive(:new).and_return(
          double('one', mimetype: 'image/tiff', filesize: 63_468, object_type: :image, exif: exif),
          double('two', mimetype: 'image/jp2', filesize: 465, object_type: :document)
        )
      end

      it 'does not overwrite them' do
        expect(item).to receive(:persist_content_metadata)
        result
        expect(item.cm.root['type']).to eq 'image'

        # check that the file nodes still have bogus size, mimetype
        aft_file_nodes = item.cm.xpath('//file')
        expect(aft_file_nodes.size).to eq(2)
        expect(aft_file_nodes[0].attributes['size'].value).to eq('100')
        expect(aft_file_nodes[0].attributes['mimetype'].value).to eq('crappy/mimetype')

        # all other file nodes will have their publish/preserve/shelve attributes set
        expect(aft_file_nodes[1].attributes['size'].value).to eq('500')
        expect(aft_file_nodes[1].attributes['mimetype'].value).to eq('crappy/again')

        # check that each resource node end with a type="file" (i.e. was not changed)
        aft_res_nodes = item.cm.xpath('//resource')
        expect(aft_res_nodes.size).to eq(1)
        expect(aft_res_nodes[0].attributes['type'].value).to eq('file') # first resource type should be set to file (default when not all files are images)

        # check for imageData nodes being present for each file node that is an image
        expect(item.cm.xpath('//file/imageData').size).to eq(1)
      end
    end

    context 'when there are existing contentmetadata type and resource types' do
      let(:xml) do
        <<~XML
          <contentMetadata type="file" objectId="ff222cc3333">
              <resource sequence="1" id="ff222cc3333_1">
                  <label>Side 1</label>
                  <file preserve="yes" publish="yes" shelve="yes" id="image111.tif">
                      <checksum type="md5">42616f9e6c1b7e7b7a71b4fa0c5ef794</checksum>
                  </file>
                  <file id="image111.jp2" />
                  <file id="file111.wav">
                      <checksum type="md5">42616f9e6c1b7e7b7a71b4fa0c5ef7XX</checksum>
                  </file>
                 <file id="file111.pdf">
                      <checksum type="md5">42616f9e6c1b7e7b7a71b4fa0c5ef7XX</checksum>
                  </file>
              </resource>
              <resource sequence="2" id="ff222cc3333_2">
                  <label>Side 2</label>
                  <file id="file112.pdf">
                    <checksum type="md5">42616f9e6c1b7e7b7a71b4fa0c5ef7XX</checksum>
                  </file>
                  <file id="image112.tif">
                      <checksum type="md5">42616f9e6c1b7e7b7a71b4fa0c5ef794</checksum>
                  </file>
                  <file id="file111.mp3">
                      <checksum type="md5">42616f9e6c1b7e7b7a71b4fa0c5ef7XX</checksum>
                  </file>
              </resource>
              <resource sequence="3" id="ff222cc3333_3">
                  <label>Side 3</label>
                  <file id="image113.tif">
                      <checksum type="md5">42616f9e6c1b7e7b7a71b4fa0c5ef794</checksum>
                  </file>
             </resource>
              <resource type="page" sequence="4" id="ff222cc3333_3">
                  <label>Side 3</label>
                  <file id="image114.tif">
                      <checksum type="md5">42616f9e6c1b7e7b7a71b4fa0c5ef794</checksum>
                  </file>
             </resource>
              <resource type="image" sequence="5" id="ff222cc3333_3">
                  <label>Side 4</label>
                  <file id="image115.tif">
                      <checksum type="md5">42616f9e6c1b7e7b7a71b4fa0c5ef794</checksum>
                  </file>
             </resource>
           </contentMetadata>

        XML
      end

      let(:druid) { 'druid:ff222cc3333' }

      before do
        allow(Assembly::ObjectFile).to receive(:new).and_return(
          double('one', mimetype: 'image/tiff', filesize: 63_468, object_type: :image, exif: exif),
          double('two', mimetype: 'image/jp2', filesize: 465, object_type: :image, exif: exif),
          double('three', mimetype: 'audio/x-wav', filesize: 450_604, object_type: 'audio'),
          double('four', mimetype: 'application/pdf', filesize: 3151, object_type: :doc),
          double('five', mimetype: 'application/pdf', filesize: 3151, object_type: :doc),
          double('six', mimetype: 'image/tiff', filesize: 63_468, object_type: :image, exif: exif),
          double('seven', mimetype: 'audio/mpeg', filesize: 42_212, object_type: 'audio'),
          double('eight', mimetype: 'image/tiff', filesize: 63_468, object_type: :image, exif: exif),
          double('nine', mimetype: 'image/tiff', filesize: 63_468, object_type: :image, exif: exif),
          double('ten', mimetype: 'image/tiff', filesize: 63_468, object_type: :image, exif: exif)
        )
      end

      it 'does not overwrite existing content metadata type and resource types' do
        expect(item).to receive(:persist_content_metadata)
        result

        # check that the content metadata type is preserved as file and not switched to image
        expect(item.cm.root['type']).to eq 'file'

        # check that the file nodes now have the correct size, mimetype
        aft_file_nodes = item.cm.xpath('//file')
        expect(aft_file_nodes.size).to eq(10)
        expect(aft_file_nodes[0].attributes['size'].value).to eq('63468')
        expect(aft_file_nodes[0].attributes['mimetype'].value).to eq('image/tiff')
        # the first file node should preserve the existing publish/preserve/shelve attributes set in the incoming content metadata and not overwrite them with the default for tiff
        expect(aft_file_nodes[0].attributes['publish'].value).to eq('yes')
        expect(aft_file_nodes[0].attributes['preserve'].value).to eq('yes')
        expect(aft_file_nodes[0].attributes['shelve'].value).to eq('yes')

        # all other file nodes will have their publish/preserve/shelve attributes set
        expect(aft_file_nodes[1].attributes['size'].value).to eq('465')
        expect(aft_file_nodes[1].attributes['mimetype'].value).to eq('image/jp2')
        expect(aft_file_nodes[1].attributes['publish'].value).to eq('yes')
        expect(aft_file_nodes[1].attributes['preserve'].value).to eq('no')
        expect(aft_file_nodes[1].attributes['shelve'].value).to eq('yes')

        expect(aft_file_nodes[2].attributes['size'].value).to eq('450604')
        expect(aft_file_nodes[2].attributes['mimetype'].value).to eq('audio/x-wav')
        expect(aft_file_nodes[2].attributes['publish'].value).to eq('no')
        expect(aft_file_nodes[2].attributes['preserve'].value).to eq('yes')
        expect(aft_file_nodes[2].attributes['shelve'].value).to eq('no')

        expect(aft_file_nodes[3].attributes['size'].value).to eq('3151')
        expect(aft_file_nodes[3].attributes['mimetype'].value).to eq('application/pdf')
        expect(aft_file_nodes[3].attributes['publish'].value).to eq('yes')
        expect(aft_file_nodes[3].attributes['preserve'].value).to eq('yes')
        expect(aft_file_nodes[3].attributes['shelve'].value).to eq('yes')

        expect(aft_file_nodes[4].attributes['size'].value).to eq('3151')
        expect(aft_file_nodes[4].attributes['mimetype'].value).to eq('application/pdf')
        expect(aft_file_nodes[4].attributes['publish'].value).to eq('yes')
        expect(aft_file_nodes[4].attributes['preserve'].value).to eq('yes')
        expect(aft_file_nodes[4].attributes['shelve'].value).to eq('yes')

        expect(aft_file_nodes[5].attributes['size'].value).to eq('63468')
        expect(aft_file_nodes[5].attributes['mimetype'].value).to eq('image/tiff')
        expect(aft_file_nodes[5].attributes['publish'].value).to eq('no')
        expect(aft_file_nodes[5].attributes['preserve'].value).to eq('yes')
        expect(aft_file_nodes[5].attributes['shelve'].value).to eq('no')

        expect(aft_file_nodes[6].attributes['size'].value).to eq('42212')
        expect(aft_file_nodes[6].attributes['mimetype'].value).to eq('audio/mpeg')
        expect(aft_file_nodes[6].attributes['publish'].value).to eq('yes')
        expect(aft_file_nodes[6].attributes['preserve'].value).to eq('no')
        expect(aft_file_nodes[6].attributes['shelve'].value).to eq('yes')

        expect(aft_file_nodes[7].attributes['size'].value).to eq('63468')
        expect(aft_file_nodes[7].attributes['mimetype'].value).to eq('image/tiff')
        expect(aft_file_nodes[7].attributes['publish'].value).to eq('no')
        expect(aft_file_nodes[7].attributes['preserve'].value).to eq('yes')
        expect(aft_file_nodes[7].attributes['shelve'].value).to eq('no')

        expect(aft_file_nodes[8].attributes['size'].value).to eq('63468')
        expect(aft_file_nodes[8].attributes['mimetype'].value).to eq('image/tiff')
        expect(aft_file_nodes[8].attributes['publish'].value).to eq('no')
        expect(aft_file_nodes[8].attributes['preserve'].value).to eq('yes')
        expect(aft_file_nodes[8].attributes['shelve'].value).to eq('no')

        expect(aft_file_nodes[9].attributes['size'].value).to eq('63468')
        expect(aft_file_nodes[9].attributes['mimetype'].value).to eq('image/tiff')
        expect(aft_file_nodes[9].attributes['publish'].value).to eq('no')
        expect(aft_file_nodes[9].attributes['preserve'].value).to eq('yes')
        expect(aft_file_nodes[9].attributes['shelve'].value).to eq('no')

        # check that each resource node end with a type="file" (i.e. was not changed)
        aft_res_nodes = item.cm.xpath('//resource')
        expect(aft_res_nodes.size).to eq(5)
        expect(aft_res_nodes[0].attributes['type'].value).to eq('file') # first resource type should be set to file (which is the default if it contains no images)
        expect(aft_res_nodes[1].attributes['type'].value).to eq('file') # second resource type should be set to file (which is the default if it contains no images)
        expect(aft_res_nodes[2].attributes['type'].nil?).to eq(true) # third resource type should be nil still
        expect(aft_res_nodes[3].attributes['type'].value).to eq('page') # fourth resource type should be set to page (which it started out as)
        expect(aft_res_nodes[4].attributes['type'].value).to eq('image') # fifth resource type should be set to image (which it started out as)

        # check for imageData nodes being present for each file node that is an image
        expect(item.cm.xpath('//file/imageData').size).to eq(6)
      end
    end
  end
end
