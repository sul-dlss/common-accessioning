# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Release::ReleaseMembers do
  before do
    @druid = 'druid:aa222cc3333'
    @work_item = instance_double(Dor::Item)
    @r = Robots::DorRepo::Release::ReleaseMembers.new
    allow(RestClient).to receive_messages(post: nil, get: nil, put: nil) # don't actually make the RestClient calls, just assume they work
  end

  it 'should run the robot' do
    setup_release_item(@druid, :item, nil)
    @r.perform(@work_item)
  end

  it 'should run the robot for an item or an apo and do nothing as a result' do
    %w[:item :apo].each do |item_type|
      setup_release_item(@druid, item_type, nil)
      expect(@release_item.is_collection?).to be false # definitely not a collection
      expect(@r).to_not receive(:item_members) # we won't bother looking for item members if this is an item
      @r.perform(@work_item)
    end
  end

  it 'should run for a collection but never add workflow or ask for item members when the collection is released to self only' do
    members = { 'sets' => [{ 'druid' => 'druid:bb001zc5754', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'French Grand Prix and 12 Hour Rheims: 1954', 'catkey' => '3051728' }] }
    setup_release_item(@druid, :collection, members)
    allow(@dor_item).to receive_messages(get_newest_release_tag: { 'SearchWorks' => { 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' } })
    allow(@dor_item).to receive_messages(release_tags: { 'SearchWorks' => [{ 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' }] })
    expect(@release_item.is_collection?).to be true
    expect(@release_item.item_members).to eq([])
    expect(@release_item.sub_collections).to eq(members['sets'])
    expect(@release_item).to_not receive(:item_members)
    expect(Dor::Release::Item).to receive(:create_workflow).once # one workflow added for the sub-collection
    @r.perform(@work_item)
  end

  it 'should run for a collection but never add workflow or ask for item members when there are multiple targets but they are all released to self only' do
    members = { 'collections' => [{ 'druid' => 'druid:bb001zc5754', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'French Grand Prix and 12 Hour Rheims: 1954', 'catkey' => '3051728' }] }
    setup_release_item(@druid, :collection, members)
    allow(@dor_item).to receive_messages(get_newest_release_tag: { 'SearchWorks' => { 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' },
                                                                   'Revs' => { 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'petucket' } })
    allow(@dor_item).to receive_messages(release_tags: { 'SearchWorks' => [{ 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' },
                                                                           'Revs' => { 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'petucket' }] })
    expect(@release_item.is_collection?).to be true
    expect(@release_item.item_members).to eq([])
    expect(@release_item.sub_collections).to eq(members['collections'])
    expect(@release_item).to_not receive(:item_members)
    expect(Dor::Release::Item).to receive(:create_workflow).once # one workflow added for the sub-collection
    @r.perform(@work_item)
  end

  it 'should run for a collection and execute the item_members method when the collection is not released to self' do
    members = { 'items' => [{ 'druid' => 'druid:bb001zc5754', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'French Grand Prix and 12 Hour Rheims: 1954', 'catkey' => '3051728' },
                            { 'druid' => 'druid:bb023nj3137', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'Snetterton Vanwall Trophy: 1958', 'catkey' => '3051732' },
                            { 'druid' => 'druid:bb027yn4436', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'Crystal Palace BARC: 1954', 'catkey' => '3051733' },
                            { 'druid' => 'druid:bb048rn5648', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => '', 'catkey' => '3051734' }] }
    setup_release_item(@druid, :collection, members)
    allow(@dor_item).to receive_messages(get_newest_release_tag: { 'SearchWorks' => { 'release' => true, 'what' => 'collection', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' } })
    allow(@dor_item).to receive_messages(release_tags: { 'SearchWorks' => [{ 'release' => true, 'what' => 'collection', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' }] })
    expect(@release_item.is_collection?).to be true
    expect(@release_item.item_members).to eq(members['items'])
    expect(@release_item.sub_collections).to eq([])
    expect(Dor::Release::Item).to receive(:add_workflow_for_item).exactly(4).times # four workflows added, one for each item
    @r.perform(@work_item)
  end

  it 'should run for a collection and execute the item_members method when there are multiple targets and at least one of the release tagets is not released to self' do
    members = { 'items' => [{ 'druid' => 'druid:bb001zc5754', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'French Grand Prix and 12 Hour Rheims: 1954', 'catkey' => '3051728' },
                            { 'druid' => 'druid:bb023nj3137', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'Snetterton Vanwall Trophy: 1958', 'catkey' => '3051732' },
                            { 'druid' => 'druid:bb027yn4436', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'Crystal Palace BARC: 1954', 'catkey' => '3051733' },
                            { 'druid' => 'druid:bb048rn5648', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => '', 'catkey' => '3051734' }] }
    setup_release_item(@druid, :collection, members)
    allow(@dor_item).to receive_messages(get_newest_release_tag: { 'SearchWorks' => { 'release' => true, 'what' => 'collection', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' },
                                                                   'Revs' => { 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'petucket' } })
    allow(@dor_item).to receive_messages(release_tags: { 'SearchWorks' => [{ 'release' => true, 'what' => 'collection', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' },
                                                                           'Revs' => { 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'petucket' }] })
    expect(@release_item.is_collection?).to be true
    expect(@release_item.item_members).to eq(members['items'])
    expect(Dor::Release::Item).to receive(:add_workflow_for_item).exactly(4).times # four workflows added, one for each item
    @r.perform(@work_item)
  end

  it 'should run for a collection and execute the sub_collection method' do
    collections = [{ 'druid' => 'druid:bb001zc5754' }, { 'druid' => 'druid:bb023nj3137' }]
    setup_release_item(@druid, :collection, 'collections' => collections)
    allow(@dor_item).to receive_messages(get_newest_release_tag: { 'SearchWorks' => { 'release' => true, 'what' => 'collection', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' } })
    allow(@dor_item).to receive_messages(release_tags: { 'SearchWorks' => [{ 'release' => true, 'what' => 'collection', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' }] })
    expect(@release_item.is_collection?).to be true
    expect(@release_item.item_members).to eq([])
    expect(@release_item.sub_collections).to eq(collections)
    expect(Dor::Release::Item).to receive(:add_workflow_for_collection).exactly(2).times # two workflows added, one for each collection
    @r.perform(@work_item)
  end

  it 'should run for a collection and execute the sub_collection method but not add a workflow for the collection itself' do
    collections = [{ 'druid' => 'druid:bb001zc5754' }, { 'druid' => 'druid:bb023nj3137' }]
    setup_release_item(@druid, :collection, 'collections' => collections + [{ 'druid' => @druid }]) # add self to the list of collections since this is what purl-fetcher does
    allow(@dor_item).to receive_messages(get_newest_release_tag: { 'SearchWorks' => { 'release' => true, 'what' => 'collection', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' } })
    allow(@dor_item).to receive_messages(release_tags: { 'SearchWorks' => [{ 'release' => true, 'what' => 'collection', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' }] })
    expect(@release_item.is_collection?).to be true
    expect(@release_item.item_members).to eq([])
    expect(@release_item.sub_collections).to eq(collections) # it has removed itself and is back to the original list
    expect(Dor::Release::Item).to receive(:add_workflow_for_collection).exactly(2).times # only two workflows added (it doesn't add a workflow for itself)
    @r.perform(@work_item)
  end
end
