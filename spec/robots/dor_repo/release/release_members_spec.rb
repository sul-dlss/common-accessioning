# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Release::ReleaseMembers do
  subject(:perform) { test_perform(robot, druid) }

  let(:robot) { described_class.new }
  let(:druid) { 'druid:bb222cc3333' }

  let(:release_tags) { [] }
  let(:release_tag_client) { instance_double(Dor::Services::Client::ReleaseTags, list: release_tags) }
  let(:members) { [] }

  let(:process_response) { instance_double(Dor::Services::Response::Process, lane_id: 'default') }
  let(:workflow_response) { instance_double(Dor::Services::Response::Workflow, process_for_recent_version: process_response) }
  let(:object_workflow) { instance_double(Dor::Services::Client::ObjectWorkflow, process: workflow_process, find: workflow_response) }
  let(:workflow_process) { instance_double(Dor::Services::Client::Process, update: true, update_error: true, status: 'queued') }
  let(:milestones) { instance_double(Dor::Services::Client::Milestones) }

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, members:, release_tags: release_tag_client, workflow: object_workflow, milestones:) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(milestones).to receive(:date).and_return(1.day.ago, 1.day.ago, 1.day.ago, nil)
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
      build(:collection, id: 'druid:bc123df4567').new(
        administrative: {
          hasAdminPolicy: 'druid:xx999xx9999'
        }
      )
    end

    context 'when the collection is released to self only' do
      let(:release_tag1) { Dor::Services::Client::ReleaseTag.new(to: 'Searchworks', release: true, what: 'self', date: '2016-10-07 19:34:43 UTC', who: 'lmcrae') }
      let(:release_tags) { [release_tag1] }

      let(:members) do
        [Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb001zc5754', version: 1)]
      end

      it 'does not add workflow for item members' do
        expect(object_workflow).not_to receive(:create)
        perform
      end
    end

    context 'when there are multiple targets but they are all released to self only' do
      let(:release_tag1) { Dor::Services::Client::ReleaseTag.new(to: 'Searchworks', release: true, what: 'self', date: '2016-10-07 19:34:43 UTC', who: 'lmcrae') } # rubocop:disable RSpec/IndexedLet
      let(:release_tag2) { Dor::Services::Client::ReleaseTag.new(to: 'Earthworks', release: true, what: 'self', date: '2016-10-07 19:34:43 UTC', who: 'petucket') } # rubocop:disable RSpec/IndexedLet
      let(:release_tags) { [release_tag1, release_tag2] }
      let(:members) do
        [Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb001zc5754', version: 1)]
      end

      it 'does not add workflow for item members' do
        expect(object_workflow).not_to receive(:create)
        perform
      end
    end

    context 'with multiple tags for a single target' do
      let(:release_tag1) { Dor::Services::Client::ReleaseTag.new(to: 'Searchworks', release: true, what: 'self', date: '2019-03-09 19:34:43 UTC', who: 'hfrost ') } # rubocop:disable RSpec/IndexedLet
      let(:release_tag2) { Dor::Services::Client::ReleaseTag.new(to: 'Searchworks', release: false, what: 'self', date: '2020-02-07 19:34:43 UTC', who: 'jkalchik') } # rubocop:disable RSpec/IndexedLet
      let(:release_tags) { [release_tag1, release_tag2] }
      let(:members) do
        [Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb001zc5754', version: 1)]
      end

      it 'does not add workflow for item members' do
        expect(object_workflow).not_to receive(:create)
        perform
      end
    end

    context 'when the collection is not released to self' do
      let(:release_tag1) { Dor::Services::Client::ReleaseTag.new(to: 'Searchworks', release: true, what: 'collection', date: '2016-10-07 19:34:43 UTC', who: 'lmcrae') }
      let(:release_tags) { [release_tag1] }
      let(:members) do
        [
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb001zc5754', version: 1),
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb023nj3137', version: 1),
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb027yn4436', version: 1),
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb048rn5648', version: 1)
        ]
      end

      it 'runs for a collection and execute the item_members method' do
        expect(object_workflow).to receive(:create).exactly(3).times # 3 workflows added, one for each published item

        perform
      end
    end

    context 'when there are multiple targets and at least one of the release targets is not released to self' do
      let(:release_tag1) { Dor::Services::Client::ReleaseTag.new(to: 'Searchworks', release: true, what: 'collection', date: '2016-10-07 19:34:43 UTC', who: 'lmcrae') } # rubocop:disable RSpec/IndexedLet
      let(:release_tag2) { Dor::Services::Client::ReleaseTag.new(to: 'Earthworks', release: true, what: 'self', date: '2016-10-07 19:34:43 UTC', who: 'petucket') } # rubocop:disable RSpec/IndexedLet
      let(:release_tags) { [release_tag1, release_tag2] }
      let(:members) do
        [
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb001zc5754', version: 1),
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb023nj3137', version: 1),
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb027yn4436', version: 1),
          Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:bb048rn5648', version: 1)
        ]
      end

      it 'runs for a collection and execute the item_members method' do
        expect(object_workflow).to receive(:create).exactly(3).times # 3 workflows added, one for each published item
        perform
      end
    end
  end
end
