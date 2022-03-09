# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Release::ReleaseMembers do
  subject(:perform) { robot.perform(druid) }

  let(:robot) { described_class.new }
  let(:druid) { 'druid:aa222cc3333' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client, find: cocina_model, members: members) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, current: '1') }
  let(:members) { [] }
  let(:process) { instance_double(Dor::Workflow::Response::Process, lane_id: 'default') }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil, process: process) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  context 'when the model is an item' do
    let(:cocina_model) { instance_double(Cocina::Models::DRO, collection?: false) }

    it 'does nothing' do
      expect(robot).not_to receive(:item_members) # we won't bother looking for item members if this is an item

      perform
    end
  end

  context 'when the model is an apo' do
    let(:cocina_model) { instance_double(Cocina::Models::AdminPolicy, collection?: false) }

    it 'does nothing' do
      expect(robot).not_to receive(:item_members) # we won't bother looking for item members if this is an item

      perform
    end
  end

  context 'when the model is a collection' do
    let(:release_tags) { [] }

    let(:cocina_model) do
      Cocina::Models::Collection.new(externalIdentifier: 'druid:bc123df4567',
                                     type: Cocina::Models::ObjectType.collection,
                                     label: 'my collection',
                                     version: 1,
                                     description: {
                                       title: [{ value: 'my collection' }],
                                       purl: 'https://purl.stanford.edu/bc123df4567'
                                     },
                                     access: {},
                                     administrative: {
                                       hasAdminPolicy: 'druid:xx999xx9999',
                                       releaseTags: release_tags
                                     })
    end

    context 'when the collection is released to self only' do
      let(:release_tag1) { { to: 'Searchworks', release: true, what: 'self', date: '2016-10-07 19:34:43 UTC', who: 'lmcrae' } }
      let(:release_tags) { [release_tag1] }

      let(:members) do
        [Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb001zc5754', type: 'collection')]
      end

      it 'runs for a collection but never add workflow or ask for item members' do
        expect(workflow_client).to receive(:create_workflow_by_name).once # one workflow added for the sub-collection
        perform
      end
    end

    context 'when there are multiple targets but they are all released to self only' do
      let(:release_tag1) { { to: 'Searchworks', release: true, what: 'self', date: '2016-10-07 19:34:43 UTC', who: 'lmcrae' } }
      let(:release_tag2) { { to: 'Earthworks', release: true, what: 'self', date: '2016-10-07 19:34:43 UTC', who: 'petucket' } }
      let(:release_tags) { [release_tag1, release_tag2] }
      let(:members) do
        [Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb001zc5754', type: 'collection')]
      end

      it 'runs for a collection but never adds workflow or ask for item members' do
        expect(workflow_client).to receive(:create_workflow_by_name).once # one workflow added for the sub-collection
        perform
      end
    end

    context 'with multiple tags for a single target' do
      let(:release_tag1) { { to: 'Searchworks', release: true, what: 'self', date: '2019-03-09 19:34:43 UTC', who: 'hfrost ' } }
      let(:release_tag2) { { to: 'Searchworks', release: false, what: 'self', date: '2020-02-07 19:34:43 UTC', who: 'jkalchik' } }
      let(:release_tags) { [release_tag1, release_tag2] }
      let(:members) do
        [Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb001zc5754', type: 'collection')]
      end

      it 'runs for a collection but never adds workflow or ask for item members' do
        expect(workflow_client).to receive(:create_workflow_by_name).once # one workflow added for the sub-collection
        perform
      end
    end

    context 'when the collection is not released to self' do
      let(:release_tag1) { { to: 'Searchworks', release: true, what: 'collection', date: '2016-10-07 19:34:43 UTC', who: 'lmcrae' } }
      let(:release_tags) { [release_tag1] }
      let(:members) do
        [
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb001zc5754', type: 'item'),
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb023nj3137', type: 'item'),
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb027yn4436', type: 'item'),
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb048rn5648', type: 'item')
        ]
      end

      it 'runs for a collection and execute the item_members method' do
        expect(workflow_client).to receive(:create_workflow_by_name).exactly(4).times # four workflows added, one for each item

        perform
      end
    end

    context 'when there are multiple targets and at least one of the release targets is not released to self' do
      let(:release_tag1) { { to: 'Searchworks', release: true, what: 'collection', date: '2016-10-07 19:34:43 UTC', who: 'lmcrae' } }
      let(:release_tag2) { { to: 'Earthworks', release: true, what: 'self', date: '2016-10-07 19:34:43 UTC', who: 'petucket' } }
      let(:release_tags) { [release_tag1, release_tag2] }
      let(:members) do
        [
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb001zc5754', type: 'item'),
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb023nj3137', type: 'item'),
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb027yn4436', type: 'item'),
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb048rn5648', type: 'item')
        ]
      end

      it 'runs for a collection and execute the item_members method' do
        expect(workflow_client).to receive(:create_workflow_by_name).exactly(4).times # four workflows added, one for each item
        perform
      end
    end

    context 'with sub collections' do
      let(:release_tag1) { { to: 'Searchworks', release: true, what: 'collection', date: '2016-10-07 19:34:43 UTC', who: 'lmcrae' } }
      let(:release_tags) { [release_tag1] }

      context 'with only collections' do
        let(:members) do
          [
            Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb001zc5754', type: 'collection'),
            Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb023nj3137', type: 'collection')
          ]
        end

        it 'runs for a collection and execute the sub_collection method' do
          expect(workflow_client).to receive(:create_workflow_by_name).twice # two workflows added, one for each collection
          perform
        end
      end
    end
  end
end
