# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::Shelve do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { described_class.new }

  before do
    expect(Dor).to receive(:find).with(druid).and_return(object)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }
    before do
      allow(ShelvingService).to receive(:shelve)
      perform
    end

    context 'when called on a Collection' do
      let(:object) { Dor::Collection.new }

      it 'does not shelve' do
        expect(ShelvingService).not_to have_received(:shelve)
      end
    end

    context 'when called on an Item' do
      let(:object) { Dor::Item.new }

      it 'shelves the item' do
        expect(ShelvingService).to have_received(:shelve).with(object)
      end
    end

    context 'when called on an APO' do
      let(:object) { Dor::AdminPolicyObject.new }

      it 'does not shelve' do
        expect(ShelvingService).not_to have_received(:shelve)
      end
    end
  end
end
