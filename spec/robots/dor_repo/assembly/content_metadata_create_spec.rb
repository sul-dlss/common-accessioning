# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::ContentMetadataCreate do
  subject(:result) { test_perform(robot, druid) }

  let(:druid) { 'bb111bb2222' }
  let(:robot) { described_class.new }
  let(:type) { 'item' }
  let(:cocina_model) { build(:dro, id: "druid:#{druid}") }
  let(:ng_xml) do
    Nokogiri::XML('<contentMetadata type="image"></contentMetadata>')
  end

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, update: true)
  end

  let(:cm_file_name) { 'tmp/contentMetadata.xml' }
  let(:stub_content_file_name) { 'tmp/stubContentMetadata.xml' }

  let(:item) do
    instance_double(Dor::Assembly::Item,
                    item?: type == 'item',
                    stub_content_metadata_exists?: stub_content_metadata,
                    stub_cm_file_name: stub_content_file_name,
                    convert_stub_content_metadata: true,
                    cocina_model:,
                    object_client:,
                    path_finder:)
  end

  let(:path_finder) { instance_double(Dor::Assembly::PathFinder, path_to_metadata_file: cm_file_name) }

  before do
    allow(Dor::Assembly::Item).to receive(:new).and_return(item)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(cm_file_name).and_return(content_metadata)
  end

  context 'when type is not item' do
    let(:type) { 'collection' }
    let(:content_metadata) { false }
    let(:stub_content_metadata) { false }

    it 'does not create structural metadata' do
      expect(item).not_to receive(:convert_stub_content_metadata)
      expect(object_client).not_to receive(:update)
      expect(result.status).to eq('skipped')
      expect(result.note).to eq('object is not an item')
    end
  end

  context 'when stubContentMetadata does not exist' do
    let(:content_metadata) { false }
    let(:stub_content_metadata) { false }

    it 'skips' do
      expect(result.status).to eq 'skipped'
    end
  end

  context 'when stubContentMetadata exists' do
    let(:content_metadata) { false }
    let(:stub_content_metadata) { true }

    before do
      allow(item).to receive(:convert_stub_content_metadata).and_return(build(:dro).structural)
      allow(FileUtils).to receive(:rm).with(stub_content_file_name)
    end

    it 'converts stub content metadata' do
      expect(object_client).to receive(:update)
      expect(result.status).to eq('completed')
    end
  end
end
