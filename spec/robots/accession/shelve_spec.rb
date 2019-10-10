# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::Shelve do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { described_class.new }
  let(:object_client) { instance_double(Dor::Services::Client::Object, shelve: nil) }

  before do
    expect(Dor).to receive(:find).with(druid).and_return(object)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    before do
      perform
    end

    context 'when called on a Collection' do
      let(:object) { Dor::Collection.new }

      it 'does not shelve' do
        expect(object_client).not_to have_received(:shelve)
      end
    end

    context 'when called on an Item' do
      let(:object) { Dor::Item.new }

      it 'shelves the item' do
        expect(object_client).to have_received(:shelve)
      end
    end

    context 'when called on an APO' do
      let(:object) { Dor::AdminPolicyObject.new }

      it 'does not shelve' do
        expect(object_client).not_to have_received(:shelve)
      end
    end
  end
end
