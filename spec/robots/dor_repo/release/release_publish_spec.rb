# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Release::ReleasePublish do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'bb222cc3333' }
  let(:robot) { described_class.new }
  let(:object_client) { instance_double(Dor::Services::Client::Object, release_tags: release_tags_client) }
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: release_tags) }
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
  end

  it 'calls purl fetcher with the release tags' do
    perform
    expect(PurlFetcher::Client).to have_received(:configure).with(url: Settings.purl_fetcher.url, token: Settings.purl_fetcher.token)
    expect(PurlFetcher::Client::ReleaseTags).to have_received(:release).with(druid:, index: ['Searchworks', 'Purl sitemap'], delete: ['Earthworks'])
  end
end
