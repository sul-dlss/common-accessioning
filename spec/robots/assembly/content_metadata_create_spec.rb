# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::ContentMetadataCreate do
  let(:druid) { 'aa111bb2222' }
  let(:robot) { described_class.new(druid: druid) }
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

  subject(:result) { robot.perform(druid) }

  context 'if type is not item' do
    let(:type) { 'collection' }
    let(:content_metadata) { false }
    let(:stub_content_metadata) { false }

    it 'does not create content metadata' do
      expect(item).not_to receive(:convert_stub_content_metadata)
      expect(item).not_to receive(:create_basic_content_metadata)
      expect(item).not_to receive(:persist_content_metadata)
      expect(result.status).to eq('skipped')
      expect(result.note).to eq('object is not an item')
    end
  end

  context 'if contentMetadata and stub content metadata both already exists' do
    let(:content_metadata) { true }
    let(:stub_content_metadata) { true }

    it 'raises an error and does not create content metadata' do
      expect(item).not_to receive(:convert_stub_content_metadata)
      expect(item).not_to receive(:create_basic_content_metadata)
      expect(item).not_to receive(:persist_content_metadata)
      exp_msg = "#{Dor::Config.assembly.stub_cm_file_name} and #{Dor::Config.assembly.cm_file_name} both exist"
      expect { result }.to raise_error RuntimeError, exp_msg
    end
  end

  context 'if contentMetadata already exists' do
    let(:content_metadata) { true }
    let(:stub_content_metadata) { false }

    it 'does not create any content metadata' do
      expect(item).not_to receive(:convert_stub_content_metadata)
      expect(item).not_to receive(:create_basic_content_metadata)
      expect(item).not_to receive(:persist_content_metadata)
      expect(result.status).to eq('skipped')
      expect(result.note).to eq("#{Dor::Config.assembly.cm_file_name} exists")
    end
  end

  context 'if stub contentMetadata does not exist and neither does regular contentMetadata' do
    let(:content_metadata) { false }
    let(:stub_content_metadata) { false }

    it 'creates basic content metadata' do
      expect(item).not_to receive(:convert_stub_content_metadata)
      expect(item).to receive(:create_basic_content_metadata).once
      expect(item).to receive(:persist_content_metadata).once
      expect(result.status).to eq('completed')
    end
  end

  context 'if stub contentMetadata exists regular contentMetadata does not' do
    let(:content_metadata) { false }
    let(:stub_content_metadata) { true }

    it 'converts stub content metadata' do
      expect(item).to receive(:convert_stub_content_metadata).once
      expect(item).to receive(:persist_content_metadata).once
      expect(result.status).to eq('completed')
    end
  end
end
