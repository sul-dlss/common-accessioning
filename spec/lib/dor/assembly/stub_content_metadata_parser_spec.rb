# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Assembly::StubContentMetadataParser do
  describe '#stub_content_metadata_parser' do
    let(:druid) { 'druid:aa111bb3333' }
    let(:item) { Dor::Assembly::Item.new(druid: druid) }

    it 'maps content metadata types to the gem correctly' do
      ['flipbook (r-l)', 'book', 'a book (l-r)'].each do |content_type|
        allow(item).to receive(:stub_object_type).and_return(content_type)
        expect(item.gem_content_metadata_style).to eq(:simple_book)
      end
      allow(item).to receive(:stub_object_type).and_return('image')
      expect(item.gem_content_metadata_style).to eq(:simple_image)
      allow(item).to receive(:stub_object_type).and_return('maps')
      expect(item.gem_content_metadata_style).to eq(:map)
      %w[3d 3D].each do |content_type|
        allow(item).to receive(:stub_object_type).and_return(content_type)
        expect(item.gem_content_metadata_style).to eq(:"3d")
      end
      %w[file bogus].each do |content_type|
        allow(item).to receive(:stub_object_type).and_return(content_type)
        expect(item.gem_content_metadata_style).to eq(:file)
      end
    end
  end
end
