# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Assembly::StubContentMetadataParser do
  describe '#book_reading_order' do
    let(:druid) { 'druid:bb111bb3333' }
    let(:item) { Dor::Assembly::Item.new(druid:) }

    context 'when stub_object_type is book (ltr)' do
      it 'maps content metadata types to book correctly' do
        ['book', 'a book (l-r)', 'book (ltr)'].each do |content_type|
          allow(item).to receive(:stub_object_type).and_return(content_type)
          expect(item.book_reading_order).to eq('left-to-right')
        end
      end
    end

    context 'when stub_object_type is book (rtl)' do
      it 'maps content metadata types to book correctly' do
        ['flipbook (r-l)', 'book (rtl)'].each do |content_type|
          allow(item).to receive(:stub_object_type).and_return(content_type)
          expect(item.book_reading_order).to eq('right-to-left')
        end
      end
    end
  end

  describe '#convert_stub_content_metadata' do
    let(:item) { Dor::Assembly::Item.new(druid:) }
    let(:cocina_model) { build(:dro, type: object_type) }
    let(:object_type) { Cocina::Models::ObjectType.book }

    before do
      allow(item).to receive(:cocina_model).and_return(cocina_model)
    end

    context 'with a left-to-right book' do
      let(:druid) { 'druid:bb111bb3333' }
      let(:expected_content_metadata) do
        {
          contains: [
            {
              type: Cocina::Models::FileSetType.page,
              externalIdentifier: 'bc234fg5678_1', label: 'Optional label',
              version: 1,
              structural: {
                contains: [
                  {
                    type: 'https://cocina.sul.stanford.edu/models/file',
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/1',
                    label: 'page1.tif',
                    filename: 'page1.tif', version: 1, hasMessageDigests: [],
                    sdrGeneratedText: false, correctedForAccessibility: false,
                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                    administrative: { publish: false, sdrPreserve: true, shelve: false }
                  }, {
                    type: 'https://cocina.sul.stanford.edu/models/file',
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/2',
                    label: 'page1.txt',
                    filename: 'page1.txt', version: 1, hasMessageDigests: [],
                    sdrGeneratedText: false, correctedForAccessibility: false,
                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                    administrative: { publish: false, sdrPreserve: false, shelve: false }
                  }
                ]
              }
            }, {
              type: Cocina::Models::FileSetType.page,
              externalIdentifier: 'bc234fg5678_2', label: 'optional page 2 label',
              version: 1,
              structural: {
                contains: [
                  {
                    type: 'https://cocina.sul.stanford.edu/models/file',
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/3',
                    label: 'page2.tif',
                    filename: 'page2.tif', version: 1, hasMessageDigests: [],
                    sdrGeneratedText: false, correctedForAccessibility: false,
                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                    administrative: { publish: false, sdrPreserve: true, shelve: false }
                  }, {
                    type: 'https://cocina.sul.stanford.edu/models/file',
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/4',
                    label: 'some_filename.txt',
                    filename: 'some_filename.txt', version: 1,
                    use: 'transcription', hasMessageDigests: [],
                    sdrGeneratedText: false, correctedForAccessibility: false,
                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                    administrative: { publish: false, sdrPreserve: true, shelve: false }
                  }
                ]
              }
            }, {
              type: Cocina::Models::FileSetType.object,
              externalIdentifier: 'bc234fg5678_3', label: 'Object 1', version: 1,
              structural: {
                contains: [
                  {
                    type: 'https://cocina.sul.stanford.edu/models/file',
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/5',
                    label: 'whole_book.pdf', filename: 'whole_book.pdf', version: 1, hasMessageDigests: [],
                    sdrGeneratedText: false, correctedForAccessibility: false,
                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                    administrative: { publish: false, sdrPreserve: false, shelve: false }
                  }
                ]
              }
            }
          ],
          hasMemberOrders: [{ members: [], viewingDirection: 'left-to-right' }],
          isMemberOf: []
        }
      end

      before do
        allow(SecureRandom).to receive(:uuid).and_return('1', '2', '3', '4', '5')
      end

      it 'generates structural metadata' do
        structural = item.convert_stub_content_metadata
        expect(structural.to_h).to eq expected_content_metadata
      end
    end

    context 'with a right-to-left book' do
      let(:druid) { 'druid:bb111bb5555' }
      let(:expected_content_metadata) do
        {
          contains: [
            {
              type: Cocina::Models::FileSetType.page,
              externalIdentifier: 'bc234fg5678_1', label: 'Optional label',
              version: 1,
              structural: {
                contains: [
                  {
                    type: 'https://cocina.sul.stanford.edu/models/file',
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/1',
                    label: 'page1.tif',
                    filename: 'page1.tif', version: 1, hasMessageDigests: [],
                    sdrGeneratedText: false, correctedForAccessibility: false,
                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                    administrative: { publish: false, sdrPreserve: true, shelve: false }
                  }, {
                    type: 'https://cocina.sul.stanford.edu/models/file',
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/2',
                    label: 'page1.txt',
                    filename: 'page1.txt', version: 1, hasMessageDigests: [],
                    sdrGeneratedText: false, correctedForAccessibility: false,
                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                    administrative: { publish: false, sdrPreserve: false, shelve: false }
                  }
                ]
              }
            }, {
              type: Cocina::Models::FileSetType.page,
              externalIdentifier: 'bc234fg5678_2', label: 'optional page 2 label',
              version: 1,
              structural: {
                contains: [
                  {
                    type: 'https://cocina.sul.stanford.edu/models/file',
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/3',
                    label: 'page2.tif',
                    filename: 'page2.tif', version: 1, hasMessageDigests: [],
                    sdrGeneratedText: false, correctedForAccessibility: false,
                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                    administrative: { publish: false, sdrPreserve: true, shelve: false }
                  }, {
                    type: 'https://cocina.sul.stanford.edu/models/file',
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/4',
                    label: 'some_filename.txt',
                    filename: 'some_filename.txt', version: 1,
                    use: 'transcription', hasMessageDigests: [],
                    sdrGeneratedText: false, correctedForAccessibility: false,
                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                    administrative: { publish: false, sdrPreserve: true, shelve: false }
                  }
                ]
              }
            }, {
              type: Cocina::Models::FileSetType.object,
              externalIdentifier: 'bc234fg5678_3', label: 'Object 1', version: 1,
              structural: {
                contains: [
                  {
                    type: 'https://cocina.sul.stanford.edu/models/file',
                    externalIdentifier: 'https://cocina.sul.stanford.edu/file/5',
                    label: 'whole_book.pdf', filename: 'whole_book.pdf', version: 1, hasMessageDigests: [],
                    sdrGeneratedText: false, correctedForAccessibility: false,
                    access: { view: 'dark', download: 'none', controlledDigitalLending: false },
                    administrative: { publish: false, sdrPreserve: false, shelve: false }
                  }
                ]
              }
            }
          ],
          hasMemberOrders: [{ members: [], viewingDirection: 'right-to-left' }],
          isMemberOf: []
        }
      end

      before do
        allow(SecureRandom).to receive(:uuid).and_return('1', '2', '3', '4', '5')
      end

      it 'generates structural metadata' do
        structural = item.convert_stub_content_metadata
        expect(structural.to_h).to eq expected_content_metadata
      end
    end

    context 'with malformed XML' do
      let(:druid) { 'druid:bb111bb7777' }

      it 'raises an error' do
        expect { item.convert_stub_content_metadata }.to raise_error(RuntimeError, /Invalid stubContentMetadata.xml/)
      end
    end
  end
end
