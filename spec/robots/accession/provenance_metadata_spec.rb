# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::ProvenanceMetadata do
  let(:robot) { described_class.new }
  let(:druid) { 'druid:aa123bb4567' }

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    it 'skips' do
      expect(perform.status).to eq('skipped')
    end
  end
end
