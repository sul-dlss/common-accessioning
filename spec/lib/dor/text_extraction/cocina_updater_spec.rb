# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::TextExtraction::CocinaUpdater do
  subject(:updater) { described_class.new(dro:, logger:) }

  let(:druid) { 'druid:bc123df4567' }
  let(:object_type) { Cocina::Models::ObjectType.image }
  let(:dro) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: true, version: 1, type: object_type, structural:) }
  let(:logger) { instance_double(Logger) }
  let(:path) { "/some/server/path/#{filename}" }
  let(:tiff_file) { instance_double(Cocina::Models::File, filename: 'file1.tiff') }
  let(:other_tiff_file) { instance_double(Cocina::Models::File, filename: 'file2.tiff') }
  let(:tiff_fileset) { instance_double(Cocina::Models::FileSet, structural: tiff_fileset_structural) }
  let(:other_tiff_fileset) { instance_double(Cocina::Models::FileSet, structural: other_tiff_fileset_structural) }
  let(:tiff_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [tiff_file]) }
  let(:other_tiff_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [other_tiff_file]) }
  let(:structural) { instance_double(Cocina::Models::DROStructural, contains: [tiff_fileset, other_tiff_fileset]) }

  describe '#find_resource_with_stem' do
    context 'when file has matching stem' do
      let(:filename) { 'file1.xml' }

      it 'finds resource with matching stem' do
        expect(updater.send(:find_resource_with_stem, path)).to eq tiff_fileset
      end
    end

    context 'when file has extension in stem' do
      let(:filename) { 'file1_tiff.xml' }

      it 'finds resource with matching filename' do
        expect(updater.send(:find_resource_with_stem, path)).to eq tiff_fileset
      end
    end

    context 'when no matching stem exists' do
      let(:filename) { 'file3.xml' }

      it 'returns nil' do
        expect(updater.send(:find_resource_with_stem, path)).to be_nil
      end
    end
  end

  describe '#extracted_filename_with_extension' do
    context 'when no underscores exist' do
      let(:filename) { 'file1.vtt' }

      it 'returns nil' do
        expect(updater.send(:extracted_filename_with_extension, path)).to be_nil
      end
    end

    context 'when the file extension is included in the filename' do
      let(:filename) { 'file1_tiff.vtt' }

      it 'extracts filename with original extension' do
        expect(updater.send(:extracted_filename_with_extension, path)).to eq 'file1.tiff'
      end
    end

    context 'when the file extension is included in the filename and there are other underscors in the filename too' do
      let(:filename) { 'file1_cool_file_tiff.vtt' }

      it 'extracts filename with original extension' do
        expect(updater.send(:extracted_filename_with_extension, path)).to eq 'file1_cool_file.tiff'
      end
    end

    context 'when there are underscores in the filename but none are the extension' do
      let(:filename) { 'file1_cool_file.vtt' }

      # NOTE: this will not throw an exception, and in theory could end up inadventantely matching a file in a resource
      # that it should not, but this is a rare edge case ... it'll probably not match anything and be skipped
      it 'extracts a filename with something it thinks is an extension, but it actually is not' do
        expect(updater.send(:extracted_filename_with_extension, path)).to eq 'file1_cool.file'
      end
    end
  end
end
