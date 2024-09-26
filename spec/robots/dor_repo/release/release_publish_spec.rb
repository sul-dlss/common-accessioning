# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Release::ReleasePublish do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'bb222cc3333' }
  let(:cocina_model) { instance_double(Cocina::Models::DRO, dro?: true, access: dro_access) }
  let(:dro_access) { instance_double(Cocina::Models::DROAccess, view: 'world') }
  let(:robot) { described_class.new }
  let(:object_client) { instance_double(Dor::Services::Client::Object, release_tags: release_tags_client, find: cocina_model) }
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags) }
  let(:release_tags) do
    [
      Dor::Services::Client::ReleaseTag.new(
        to: 'Searchworks',
        what: 'self',
        date: '2014-08-30T01:06:28.000+00:00',
        who: 'petucket',
        release: true
      ),
      Dor::Services::Client::ReleaseTag.new(
        to: 'Purl sitemap',
        what: 'self',
        date: '2014-08-30T01:06:28.000+00:00',
        who: 'petucket',
        release: true
      ),
      Dor::Services::Client::ReleaseTag.new(
        to: 'Earthworks',
        what: 'self',
        date: '2014-08-30T01:06:28.000+00:00',
        who: 'petucket',
        release: false
      )
    ]
  end

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(PurlFetcher::Client).to receive(:configure)
    allow(PurlFetcher::Client::ReleaseTags).to receive(:release)
    allow(release_tags_client).to receive(:list).with(public: true).and_return(release_tags)
  end

  context 'when the model is an item that is not dark' do
    it 'calls purl fetcher with the release tags' do
      perform
      expect(PurlFetcher::Client).to have_received(:configure).with(url: Settings.purl_fetcher.url, token: Settings.purl_fetcher.token)
      expect(PurlFetcher::Client::ReleaseTags).to have_received(:release).with(druid:, index: ['Searchworks', 'Purl sitemap'], delete: ['Earthworks'])
    end
  end

  context 'when the model is an item that is dark' do
    let(:dro_access) { instance_double(Cocina::Models::DROAccess, view: 'dark') }

    it 'skips publishing' do
      expect(perform).to have_attributes(status: 'skipped')
      expect(PurlFetcher::Client).not_to have_received(:configure)
      expect(PurlFetcher::Client::ReleaseTags).not_to have_received(:release)
    end
  end

  context 'when the model is an apo' do
    let(:cocina_model) { instance_double(Cocina::Models::AdminPolicy, dro?: false) }

    it 'calls purl fetcher with the release tags' do
      perform
      expect(PurlFetcher::Client).to have_received(:configure).with(url: Settings.purl_fetcher.url, token: Settings.purl_fetcher.token)
      expect(PurlFetcher::Client::ReleaseTags).to have_received(:release).with(druid:, index: ['Searchworks', 'Purl sitemap'], delete: ['Earthworks'])
    end
  end
end
