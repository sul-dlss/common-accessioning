# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::StagedContent do
  subject(:staged_content) { described_class.find(druid) }

  let(:druid) { 'druid:bc123df4567' }
  let(:assembly_root) { Dir.mktmpdir }
  let(:staging_root) { Dir.mktmpdir }
  let(:assembly_pathname) { DruidTools::Druid.new(druid, assembly_root).pathname }
  let(:staging_pathname) { DruidTools::Druid.new(druid, staging_root).pathname }

  before do
    allow(Settings.sdr).to receive_messages(assembly_root:, staging_root:)
  end

  after do
    FileUtils.rm_rf(assembly_root)
    FileUtils.rm_rf(staging_root)
  end

  context 'when in the assembly root' do
    before { assembly_pathname.mkpath }

    it 'returns the assembly location' do
      expect(staged_content.root).to eq(:assembly)
      expect(staged_content).to be_assembly
      expect(staged_content).not_to be_staging
      expect(staged_content.pathname).to eq(assembly_pathname)
    end
  end

  context 'when in the staging root' do
    before { staging_pathname.mkpath }

    it 'returns the staging location' do
      expect(staged_content.root).to eq(:staging)
      expect(staged_content).to be_staging
      expect(staged_content).not_to be_assembly
      expect(staged_content.pathname).to eq(staging_pathname)
    end
  end

  context 'when in neither root' do
    it 'returns nil' do
      expect(staged_content).to be_nil
    end
  end

  context 'when only an old-style (no druid leaf) directory exists' do
    before { assembly_pathname.parent.mkpath }

    it 'returns nil' do
      expect(staged_content).to be_nil
    end
  end

  context 'when in both roots' do
    before do
      assembly_pathname.mkpath
      staging_pathname.mkpath
    end

    it 'raises' do
      expect { staged_content }.to raise_error(Dor::StagedContent::MultipleRootsError, /#{assembly_pathname}.*#{staging_pathname}/)
    end
  end
end
