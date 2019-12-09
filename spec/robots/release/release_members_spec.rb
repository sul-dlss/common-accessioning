# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Release::ReleaseMembers do
  subject(:perform) { robot.perform(work_item) }

  let(:robot) { described_class.new }
  let(:druid) { 'druid:aa222cc3333' }
  let(:work_item) { instance_double(Dor::Item) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, current: '1') }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  it 'runs the robot' do
    setup_release_item(druid, :item, nil)
    perform
  end

  it 'runs the robot for an item or an apo and do nothing as a result' do
    %w[:item :apo].each do |item_type|
      setup_release_item(druid, item_type, nil)
      expect(@release_item.collection?).to be false # definitely not a collection
      expect(robot).not_to receive(:item_members) # we won't bother looking for item members if this is an item
      perform
    end
  end

  context 'when the collection is released to self only' do
    let(:tag_service) do
      instance_double(Dor::ReleaseTagService, newest_release_tag: { 'SearchWorks' => { 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' } },
                                              release_tags: { 'SearchWorks' => [{ 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' }] })
    end

    let(:members) do
      { 'sets' => [{ 'druid' => 'druid:bb001zc5754', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'French Grand Prix and 12 Hour Rheims: 1954', 'catkey' => '3051728' }] }
    end

    before do
      setup_release_item(druid, :collection, members)
      allow(Dor::ReleaseTagService).to receive(:for).with(@dor_item).and_return(tag_service)
    end

    it 'runs for a collection but never add workflow or ask for item members' do
      expect(@release_item.collection?).to be true
      expect(@release_item.item_members).to eq([])
      expect(@release_item.sub_collections).to eq(members['sets'])
      expect(@release_item).not_to receive(:item_members)
      expect(Dor::Config.workflow.client).to receive(:create_workflow_by_name).once # one workflow added for the sub-collection
      perform
    end
  end

  context 'when there are multiple targets but they are all released to self only' do
    let(:tag_service) do
      instance_double(Dor::ReleaseTagService, newest_release_tag: { 'SearchWorks' => { 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' },
                                                                    'Revs' => { 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'petucket' } },
                                              release_tags: { 'SearchWorks' => [{ 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' },
                                                                                'Revs' => { 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'petucket' }] })
    end
    let(:members) do
      { 'collections' => [{ 'druid' => 'druid:bb001zc5754', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'French Grand Prix and 12 Hour Rheims: 1954', 'catkey' => '3051728' }] }
    end

    before do
      setup_release_item(druid, :collection, members)
      allow(Dor::ReleaseTagService).to receive(:for).with(@dor_item).and_return(tag_service)
    end

    it 'runs for a collection but never adds workflow or ask for item members' do
      expect(@release_item.collection?).to be true
      expect(@release_item.item_members).to eq([])
      expect(@release_item.sub_collections).to eq(members['collections'])
      expect(@release_item).not_to receive(:item_members)
      expect(Dor::Config.workflow.client).to receive(:create_workflow_by_name).once # one workflow added for the sub-collection
      perform
    end
  end

  context 'when the collection is not released to self' do
    let(:tag_service) do
      instance_double(Dor::ReleaseTagService,
                      newest_release_tag: { 'SearchWorks' => { 'release' => true, 'what' => 'collection', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' } },
                      release_tags: { 'SearchWorks' => [{ 'release' => true, 'what' => 'collection', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' }] })
    end

    let(:members) do
      { 'items' => [{ 'druid' => 'druid:bb001zc5754', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'French Grand Prix and 12 Hour Rheims: 1954', 'catkey' => '3051728' },
                    { 'druid' => 'druid:bb023nj3137', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'Snetterton Vanwall Trophy: 1958', 'catkey' => '3051732' },
                    { 'druid' => 'druid:bb027yn4436', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'Crystal Palace BARC: 1954', 'catkey' => '3051733' },
                    { 'druid' => 'druid:bb048rn5648', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => '', 'catkey' => '3051734' }] }
    end

    before do
      setup_release_item(druid, :collection, members)
      allow(Dor::ReleaseTagService).to receive(:for).with(@dor_item).and_return(tag_service)
    end

    it 'runs for a collection and execute the item_members method' do
      expect(@release_item.collection?).to be true
      expect(@release_item.item_members).to eq(members['items'])
      expect(@release_item.sub_collections).to eq([])
      expect(Dor::Config.workflow.client).to receive(:create_workflow_by_name).exactly(4).times # four workflows added, one for each item

      perform
    end
  end

  context 'when there are multiple targets and at least one of the release tagets is not released to self' do
    let(:tag_service) do
      instance_double(Dor::ReleaseTagService, newest_release_tag: { 'SearchWorks' => { 'release' => true, 'what' => 'collection', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' },
                                                                    'Revs' => { 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'petucket' } },
                                              release_tags: { 'SearchWorks' => [{ 'release' => true, 'what' => 'collection', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' },
                                                                                'Revs' => { 'release' => true, 'what' => 'self', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'petucket' }] })
    end
    let(:members) do
      { 'items' => [{ 'druid' => 'druid:bb001zc5754', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'French Grand Prix and 12 Hour Rheims: 1954', 'catkey' => '3051728' },
                    { 'druid' => 'druid:bb023nj3137', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'Snetterton Vanwall Trophy: 1958', 'catkey' => '3051732' },
                    { 'druid' => 'druid:bb027yn4436', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => 'Crystal Palace BARC: 1954', 'catkey' => '3051733' },
                    { 'druid' => 'druid:bb048rn5648', 'latest_change' => '2014-06-06T05:06:06Z', 'title' => '', 'catkey' => '3051734' }] }
    end

    before do
      setup_release_item(druid, :collection, members)
      allow(Dor::ReleaseTagService).to receive(:for).with(@dor_item).and_return(tag_service)
    end

    it 'runs for a collection and execute the item_members method' do
      expect(@release_item.collection?).to be true
      expect(@release_item.item_members).to eq(members['items'])
      expect(Dor::Config.workflow.client).to receive(:create_workflow_by_name).exactly(4).times # four workflows added, one for each item
      perform
    end
  end

  context 'with sub collections' do
    let(:tag_service) do
      instance_double(Dor::ReleaseTagService, newest_release_tag: { 'SearchWorks' => { 'release' => true, 'what' => 'collection', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' } },
                                              release_tags: { 'SearchWorks' => [{ 'release' => true, 'what' => 'collection', 'when' => '2016-10-07 19:34:43 UTC', 'who' => 'lmcrae' }] })
    end

    let(:collections) { [{ 'druid' => 'druid:bb001zc5754' }, { 'druid' => 'druid:bb023nj3137' }] }

    context 'with only collections' do
      before do
        setup_release_item(druid, :collection, 'collections' => collections)
        allow(Dor::ReleaseTagService).to receive(:for).with(@dor_item).and_return(tag_service)
      end

      it 'runs for a collection and execute the sub_collection method' do
        expect(@release_item.collection?).to be true
        expect(@release_item.item_members).to eq([])
        expect(@release_item.sub_collections).to eq(collections)
        expect(Dor::Config.workflow.client).to receive(:create_workflow_by_name).twice # two workflows added, one for each collection
        perform
      end
    end

    context 'with collections and itself' do
      before do
        setup_release_item(druid, :collection, 'collections' => collections + [{ 'druid' => druid }])
        allow(Dor::ReleaseTagService).to receive(:for).with(@dor_item).and_return(tag_service)
      end

      it 'runs for a collection and execute the sub_collection method but not add a workflow for the collection itself' do
        expect(@release_item.collection?).to be true
        expect(@release_item.item_members).to eq([])
        expect(@release_item.sub_collections).to eq(collections) # it has removed itself and is back to the original list
        expect(Dor::Config.workflow.client).to receive(:create_workflow_by_name).twice # two workflows added, one for each collection
        perform
      end
    end
  end
end
