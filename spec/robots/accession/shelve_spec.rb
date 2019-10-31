# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::Shelve do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { described_class.new }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    context 'when called on a Collection or APO' do
      let(:object_client) { instance_double(Dor::Services::Client::Object) }

      before do
        allow(object_client).to receive(:shelve).and_raise(Dor::Services::Client::UnexpectedResponse)
      end

      it 'does not raise an error' do
        expect(perform).to be_nil
      end
    end

    context 'when called on an Item' do
      let(:object_client) { instance_double(Dor::Services::Client::Object, shelve: 'http://dor-services/background-job/123') }

      context "when it's successful" do
        it 'shelves the item' do
          perform
          expect(object_client).to have_received(:shelve)
        end
      end
    end
  end
end
