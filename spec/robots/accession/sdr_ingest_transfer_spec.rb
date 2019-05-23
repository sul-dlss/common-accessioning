# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::SdrIngestTransfer do
  subject(:robot) { described_class.new }

  let(:druid) { 'druid:aa222cc3333' }
  let(:object) { instance_double(Dor::Item) }

  describe '#perform' do
    before do
      allow(Dor).to receive(:find).with(druid).and_return(object)
      allow(SdrIngestService).to receive(:transfer)
    end

    it 'is successful' do
      robot.perform(druid)
      expect(SdrIngestService).to have_received(:transfer).with(object)
    end
  end
end
