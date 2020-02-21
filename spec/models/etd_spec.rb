# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Etd do
  subject(:etd) { described_class.new(pid: druid) }

  let(:druid) { 'druid:ab123cd4567' }

  describe '.find' do
    before do
      allow(Dor::Etd).to receive(:find).and_return(etd)
      etd.identityMetadata.objectType = 'item'
    end

    it 'loads the object as an Etd' do
      expect(described_class.find(druid)).to be_kind_of described_class
    end
  end
end
