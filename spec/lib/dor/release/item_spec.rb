# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Release::Item do
  before do
    @druid = 'oo000oo0001'
    @item = described_class.new(druid: @druid, skip_heartbeat: true) # skip heartbeat check for dor-fetcher
    @n = 0

    # setup doubles and mocks so we can stub out methods and not make actual dor, webservice or workflow calls
    @client = instance_double(DorFetcher::Client)
    @response = { 'items' => ['returned_members'], 'sets' => ['returned_sets'], 'collections' => ['returned_collections'] }
    allow(@client).to receive(:get_collection).and_return(@response)
    @item.fetcher = @client

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

  it 'returns false for republish_needed' do
    expect(@item).not_to be_republish_needed
  end

  it 'calls dor-fetcher-client to get the members, but only once' do
    expect(@item.fetcher).to receive(:get_collection).once
    while @n < 3
      expect(@item.members).to eq @response
      @n += 1
    end
  end

  it 'gets the right value for item_members' do
    expect(@item.item_members).to eq @response['items']
  end

  it 'gets the right value for sub_collections' do
    expect(@item.sub_collections).to eq @response['sets'] + @response['collections']
  end

  it 'creates the workflow for a collection' do
    expect(Dor::Config.workflow.client).to receive(:create_workflow_by_name).with(@druid, 'releaseWF').once

    described_class.create_release_workflow(@druid)
  end

  it 'creates the workflow for an item' do
    expect(Dor::Config.workflow.client).to receive(:create_workflow_by_name).with(@druid, 'releaseWF').once

    described_class.create_release_workflow(@druid)
  end

  it 'makes a webservice call for updating_marc_records' do
    stub_request(:post, 'https://dor-services-test.stanford.test/v1/objects/oo000oo0001/update_marc_record')
      .to_return(status: 201, body: '', headers: {})
    expect(@item.update_marc_record).to be true
  end

  it 'returns correct object types for an item' do
    allow(@dor_object).to receive(:identityMetadata).and_return(Dor::IdentityMetadataDS.from_xml('<identityMetadata><objectType>item</objectType></identityMetadata>'))
    expect(@item).to be_item
    expect(@item).not_to be_collection
    expect(@item).not_to be_set
    expect(@item).not_to be_apo
  end

  it 'returns correct object types for a set' do
    allow(@dor_object).to receive(:identityMetadata).and_return(Dor::IdentityMetadataDS.from_xml('<identityMetadata><objectType>set</objectType></identityMetadata>'))
    expect(@item).not_to be_item
    expect(@item).not_to be_collection
    expect(@item).to be_set
    expect(@item).not_to be_apo
  end

  it 'returns correct object types for a collection' do
    allow(@dor_object).to receive(:identityMetadata).and_return(Dor::IdentityMetadataDS.from_xml('<identityMetadata><objectType>collection</objectType></identityMetadata>'))
    expect(@item).not_to be_item
    expect(@item).to be_collection
    expect(@item).not_to be_set
    expect(@item).not_to be_apo
  end

  it 'returns correct object types for an apo' do
    allow(@dor_object).to receive(:identityMetadata).and_return(Dor::IdentityMetadataDS.from_xml('<identityMetadata><objectType>adminPolicy</objectType></identityMetadata>'))
    expect(@item).not_to be_item
    expect(@item).not_to be_collection
    expect(@item).not_to be_set
    expect(@item).to be_apo
  end
end
