# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::Publish do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { Robots::DorRepo::Accession::Publish.new }
  let(:object_client) { instance_double(Dor::Services::Client::Object, publish: true) }

  before do
    expect(Dor).to receive(:find).with(druid).and_return(object)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }
    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
      perform
    end

    context 'when called on a Collection' do
      let(:object) { Dor::Collection.new }

      it 'publishes metadata' do
        expect(object_client).to have_received(:publish)
      end
    end

    context 'when called on an Item' do
      let(:object) { Dor::Item.new }

      it 'publishes metadata' do
        expect(object_client).to have_received(:publish)
      end
    end

    context 'when called on an APO' do
      let(:object) { Dor::AdminPolicyObject.new }

      it 'does not publish metadata' do
        expect(object_client).not_to have_received(:publish)
      end
    end
  end
end
