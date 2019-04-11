# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::Publish do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { Robots::DorRepo::Accession::Publish.new }

  before do
    expect(Dor).to receive(:find).with(druid).and_return(object)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }
    before do
      allow(PublishMetadataService).to receive(:publish)
      perform
    end

    context 'when called on a Collection' do
      let(:object) { Dor::Collection.new }

      it 'publishes metadata' do
        expect(PublishMetadataService).to have_received(:publish).with(object)
      end
    end

    context 'when called on an Item' do
      let(:object) { Dor::Item.new }

      it 'publishes metadata' do
        expect(PublishMetadataService).to have_received(:publish).with(object)
      end
    end

    context 'when called on an APO' do
      let(:object) { Dor::AdminPolicyObject.new }

      it 'does not publish metadata' do
        expect(PublishMetadataService).not_to have_received(:publish)
      end
    end
  end
end
