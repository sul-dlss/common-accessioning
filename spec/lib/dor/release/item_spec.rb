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

    allow(Dor::WorkflowObject).to receive(:initial_repo).with('releaseWF').and_return(true)
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

  describe 'object_type' do
    subject { @item.object_type }

    before do
      allow(@dor_object).to receive(:identityMetadata).and_return(Dor::IdentityMetadataDS.from_xml("<identityMetadata><objectType>#{object_type}</objectType></identityMetadata>"))
    end

    context 'when object_type is item' do
      let(:object_type) { 'item' }

      it { is_expected.to eq 'item' }
    end

    context 'when object_type is set' do
      let(:object_type) { 'set' }

      it { is_expected.to eq 'set' }
    end

    context 'when object_type is collection' do
      let(:object_type) { 'collection' }

      it { is_expected.to eq 'collection' }
    end

    context 'when object_type is adminPolicy' do
      let(:object_type) { 'adminPolicy' }

      it { is_expected.to eq 'adminpolicy' }
    end
  end
end
