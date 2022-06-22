# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::ContentMetadataCreate do
  subject(:result) { robot.perform(druid) }

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
  let(:item) do
    instance_double(Dor::Assembly::Item,
                    item?: type == 'item',
                    stub_content_metadata_exists?: stub_content_metadata,
                    convert_stub_content_metadata: true,
                    cocina_model: cocina_model,
                    object_client: object_client,
                    path_finder: path_finder)
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

    it 'does not create content metadata' do
      expect(item).not_to receive(:convert_stub_content_metadata)
      expect(object_client).not_to receive(:update)
      expect(result.status).to eq('skipped')
      expect(result.note).to eq('object is not an item')
    end
  end

  context 'when contentMetadata and stub content metadata both already exist' do
    let(:content_metadata) { true }
    let(:stub_content_metadata) { true }

    it 'raises an error and does not create content metadata' do
      expect(item).not_to receive(:convert_stub_content_metadata)
      expect(object_client).not_to receive(:update)
      exp_msg = "#{Settings.assembly.stub_cm_file_name} and #{Settings.assembly.cm_file_name} both exist for #{druid}"
      expect { result }.to raise_error RuntimeError, exp_msg
    end
  end

  context 'when contentMetadata.xml exists' do
    let(:content_metadata) { true }
    let(:stub_content_metadata) { false }

    before do
      allow(File).to receive(:read).with(cm_file_name).and_return('<contentMetadata type="image"></contentMetadata>')
      allow(FileUtils).to receive(:rm).with(cm_file_name)
    end

    it 'converts it to cocina' do
      expect(item).not_to receive(:convert_stub_content_metadata)
      result
      expect(object_client).to have_received(:update)
    end
  end

  context 'when stub contentMetadata does not exist and neither does regular contentMetadata' do
    let(:content_metadata) { false }
    let(:stub_content_metadata) { false }

    it 'skips' do
      expect(result.status).to eq 'skipped'
    end
  end

  context 'when stub contentMetadata exists regular contentMetadata does not' do
    let(:content_metadata) { false }
    let(:stub_content_metadata) { true }

    before do
      allow(item).to receive(:convert_stub_content_metadata).and_return('<contentMetadata type="image"></contentMetadata>')
    end

    it 'converts stub content metadata' do
      expect(object_client).to receive(:update)
      expect(result.status).to eq('completed')
    end
  end
end
