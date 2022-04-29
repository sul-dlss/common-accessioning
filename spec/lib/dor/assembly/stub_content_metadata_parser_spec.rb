# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Assembly::StubContentMetadataParser do
  describe '#stub_content_metadata_parser' do
    let(:druid) { 'druid:bb111bb3333' }
    let(:druid_rtl) { 'druid:bb111bb5555' }
    let(:item) { Dor::Assembly::Item.new(druid: druid) }
    let(:item_rtl) { Dor::Assembly::Item.new(druid: druid_rtl) }

    let(:xml_doc) do
      <<-EOXML
      <?xml version="1.0"?>
      <contentMetadata objectId="druid:bb111bb3333" type="book">
        <bookData readingOrder="ltr"/>
        <resource id="bb111bb3333_1" sequence="1" type="object">
          <label>Optional label</label>
          <file id="page1.tif" preserve="yes" shelve="no" publish="no"/>
          <file id="page1.txt" preserve="no" shelve="no" publish="no"/>
        </resource>
        <resource id="bb111bb3333_2" sequence="2" type="object">
          <label>optional page 2 label</label>
          <file id="page2.tif" preserve="yes" shelve="no" publish="no"/>
          <file id="some_filename.txt" preserve="yes" shelve="no" publish="no" role="transcription"/>
        </resource>
        <resource id="bb111bb3333_3" sequence="3" type="object">
          <label>Object 3</label>
          <file id="whole_book.pdf" preserve="no" shelve="no" publish="no"/>
        </resource>
      </contentMetadata>
      EOXML
    end

    let(:xml_doc_rtl) do
      <<-EOXML
      <?xml version="1.0"?>
      <contentMetadata objectId="druid:bb111bb5555" type="book">
        <bookData readingOrder="rtl"/>
        <resource id="bb111bb5555_1" sequence="1" type="object">
          <label>Optional label</label>
          <file id="page1.tif" preserve="yes" shelve="no" publish="no"/>
          <file id="page1.txt" preserve="no" shelve="no" publish="no"/>
        </resource>
        <resource id="bb111bb5555_2" sequence="2" type="object">
          <label>optional page 2 label</label>
          <file id="page2.tif" preserve="yes" shelve="no" publish="no"/>
          <file id="some_filename.txt" preserve="yes" shelve="no" publish="no" role="transcription"/>
        </resource>
        <resource id="bb111bb5555_3" sequence="3" type="object">
          <label>Object 3</label>
          <file id="whole_book.pdf" preserve="no" shelve="no" publish="no"/>
        </resource>
      </contentMetadata>
      EOXML
    end

    context 'when stub_object_type is book (ltr)' do
      it 'maps content metadata types to book correctly' do
        ['book', 'a book (l-r)', 'book (ltr)'].each do |content_type|
          allow(item).to receive(:stub_object_type).and_return(content_type)
          expect(item.gem_content_metadata_style).to eq(:simple_book)
          expect(item.book_reading_order).to eq('ltr')
        end
      end
    end

    context 'when stub_object_type is book (rtl)' do
      it 'maps content metadata types to book correctly' do
        ['flipbook (r-l)', 'book (rtl)'].each do |content_type|
          allow(item).to receive(:stub_object_type).and_return(content_type)
          expect(item.gem_content_metadata_style).to eq(:simple_book)
          expect(item.book_reading_order).to eq('rtl')
        end
      end
    end

    context 'when stub_object_type is image' do
      it 'maps content metadata types to image correctly' do
        allow(item).to receive(:stub_object_type).and_return('image')
        expect(item.gem_content_metadata_style).to eq(:simple_image)
      end
    end

    context 'when stub_object_type is map' do
      it 'maps content metadata types to map correctly' do
        allow(item).to receive(:stub_object_type).and_return('maps')
        expect(item.gem_content_metadata_style).to eq(:map)
      end
    end

    context 'when stub_object_type is 3d' do
      it 'maps content metadata types to 3d correctly' do
        %w[3d 3D].each do |content_type|
          allow(item).to receive(:stub_object_type).and_return(content_type)
          expect(item.gem_content_metadata_style).to eq(:'3d')
        end
      end
    end

    context 'when stub_object_type is file or unknown' do
      it 'maps content metadata type to file correctly' do
        %w[file bogus].each do |content_type|
          allow(item).to receive(:stub_object_type).and_return(content_type)
          expect(item.gem_content_metadata_style).to eq(:file)
        end
      end
    end

    context 'when convert_stub_content_metadata method is called for an ltr book' do
      it 'generates stub content metadata' do
        stub_xml = item.convert_stub_content_metadata
        expect(stub_xml).to be_equivalent_to xml_doc
      end
    end

    context 'when convert_stub_content_metadata method is called for an rtl book' do
      it 'generates stub content metadata' do
        stub_xml = item_rtl.convert_stub_content_metadata
        expect(stub_xml).to be_equivalent_to xml_doc_rtl
      end
    end
  end
end
