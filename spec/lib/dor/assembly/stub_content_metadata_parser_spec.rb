# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Assembly::StubContentMetadataParser do
  describe '#stub_content_metadata_parser' do
    let(:druid) { 'druid:aa111bb3333' }
    let(:item) { Dor::Assembly::Item.new(druid: druid) }

    context 'when stub_object_type is book' do
      it 'maps content metadata types to book correctly' do
        ['flipbook (r-l)', 'book', 'a book (l-r)'].each do |content_type|
          allow(item).to receive(:stub_object_type).and_return(content_type)
          expect(item.gem_content_metadata_style).to eq(:simple_book)
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
          expect(item.gem_content_metadata_style).to eq(:"3d")
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
  end
end
