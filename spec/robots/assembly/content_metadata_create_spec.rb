# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::ContentMetadataCreate do
  subject(:result) { robot.perform(druid) }

  let(:druid) { 'bb111bb2222' }
  let(:robot) { described_class.new }
  let(:type) { 'item' }

  let(:item) do
    instance_double(Dor::Assembly::Item,
                    item?: type == 'item',
                    stub_content_metadata_exists?: stub_content_metadata,
                    content_metadata_exists?: content_metadata,
                    convert_stub_content_metadata: true,
                    persist_content_metadata: true)
  end

  before do
    allow(Dor::Assembly::Item).to receive(:new).and_return(item)
  end

  context 'when type is not item' do
    let(:type) { 'collection' }
    let(:content_metadata) { false }
    let(:stub_content_metadata) { false }

    it 'does not create content metadata' do
      expect(item).not_to receive(:convert_stub_content_metadata)
      expect(item).not_to receive(:persist_content_metadata)
      expect(result.status).to eq('skipped')
      expect(result.note).to eq('object is not an item')
    end
  end

  context 'when contentMetadata and stub content metadata both already exist' do
    let(:content_metadata) { true }
    let(:stub_content_metadata) { true }

    it 'raises an error and does not create content metadata' do
      expect(item).not_to receive(:convert_stub_content_metadata)
      expect(item).not_to receive(:persist_content_metadata)
      exp_msg = "#{Settings.assembly.stub_cm_file_name} and #{Settings.assembly.cm_file_name} both exist for #{druid}"
      expect { result }.to raise_error RuntimeError, exp_msg
    end
  end

  context 'when contentMetadata already exists' do
    let(:content_metadata) { true }
    let(:stub_content_metadata) { false }

    it 'does not create any content metadata' do
      expect(item).not_to receive(:convert_stub_content_metadata)
      expect(item).not_to receive(:persist_content_metadata)
      expect(result.status).to eq('skipped')
      expect(result.note).to eq("#{Settings.assembly.cm_file_name} exists")
    end
  end

  context 'when stub contentMetadata does not exist and neither does regular contentMetadata' do
    let(:content_metadata) { false }
    let(:stub_content_metadata) { false }

    it 'raises an error' do
      expect { result }.to raise_error RuntimeError, 'Unable to find stubContentMetadata.xml or contentMetadata.xml'
    end
  end

  context 'when stub contentMetadata exists regular contentMetadata does not' do
    let(:content_metadata) { false }
    let(:stub_content_metadata) { true }

    it 'converts stub content metadata' do
      expect(item).to receive(:convert_stub_content_metadata).once
      expect(item).to receive(:persist_content_metadata).once
      expect(result.status).to eq('completed')
    end
  end
end
