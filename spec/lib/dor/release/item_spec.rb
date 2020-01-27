# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Release::Item do
  before do
    @druid = 'oo000oo0001'
    @item = described_class.new(druid: @druid)
    @n = 0

    # setup doubles and mocks so we can stub out methods and not make actual dor, webservice or workflow calls
    @response = { 'items' => ['returned_members'], 'sets' => ['returned_sets'], 'collections' => ['returned_collections'] }
    @dor_object = instance_double(Dor::Item)
    allow(Dor).to receive(:find).and_return(@dor_object)
  end

  it 'initializes' do
    expect(@item.druid).to eq @druid
  end

  it 'calls Dor.find, but only once' do
    expect(Dor).to receive(:find).with(@druid).and_return(@dor_object).once
    while @n < 3
      expect(@item.object).to eq @dor_object
      @n += 1
    end
  end

  describe 'collection?' do
    subject { @item.collection? }

    let(:object_client) { instance_double(Dor::Services::Client::Object, find: object_type.allocate) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    context 'when object_type is item' do
      let(:object_type) { Cocina::Models::DRO }

      it { is_expected.to be false }
    end

    context 'when object_type is collection' do
      let(:object_type) { Cocina::Models::Collection }

      it { is_expected.to be true }
    end

    context 'when object_type is adminPolicy' do
      let(:object_type) { Cocina::Models::AdminPolicy }

      it { is_expected.to be false }
    end
  end
end
