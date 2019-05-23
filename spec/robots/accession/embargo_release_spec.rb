# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Robots::DorRepo::Accession::EmbargoRelease' do
  before do
    allow_any_instance_of(RSolr::Client).to receive(:get).and_return(
      'response' => {
        'numFound' => '1',
        'docs' => {}
      }
    )
    # must do require after mocking Solr call because loading the file calls method
    require File.expand_path(File.dirname(__FILE__) + '/../../../robots/dor_repo/accession/embargo_release')
  end

  let(:embargo_release_date) { Time.now.utc - 100000 }

  let(:release_access) {
    <<-EOXML
    <releaseAccess>
      <access type="discover">
        <machine>
          <world/>
        </machine>
      </access>
      <access type="read">
        <machine>
          <world/>
        </machine>
      </access>
    </releaseAccess>
    EOXML
  }

  let(:rights_xml) {
    <<-EOXML
    <rightsMetadata objectId="druid:rt923jk342">
      <access type="discover">
        <machine>
          <world />
        </machine>
      </access>
      <access type="read">
        <machine>
          <group>stanford</group>
          <embargoReleaseDate>#{embargo_release_date.iso8601}</embargoReleaseDate>
        </machine>
      </access>
    </rightsMetadata>
    EOXML
  }

  # TODO: #release_embargo is a method on Dor::Item (dor-services). The test should be moved there.
  describe "#release_embargo" do
    let(:embargo_xml) {
      <<-EOXML
      <embargoMetadata>
        <status>embargoed</status>
        <releaseDate>#{embargo_release_date.iso8601}</releaseDate>
        <twentyPctVisibilityStatus/>
        <twentyPctVisibilityReleaseDate/>
        #{release_access}
      </embargoMetadata>
      EOXML
    }
    let(:item) {
      i = Dor::Item.new
      rds = Dor::RightsMetadataDS.new
      rds.content = Nokogiri::XML(rights_xml) { |config| config.default_xml.noblanks }.to_s
      i.datastreams['rightsMetadata'] = rds
      eds = Dor::EmbargoMetadataDS.new
      eds.content = Nokogiri::XML(embargo_xml) { |config| config.default_xml.noblanks }.to_s
      i.datastreams['embargoMetadata'] = eds
      i
    }

    it 'rights metadata has no embargo after Dor::Item.release_embargo' do
      expect(item.rightsMetadata.ng_xml.at_xpath('//embargoReleaseDate')).not_to be_nil
      expect(item.rightsMetadata.content).to match('embargoReleaseDate')
      item.release_embargo('ignored')
      expect(item.rightsMetadata.ng_xml.at_xpath('//embargoReleaseDate')).to be_nil
      expect(item.rightsMetadata.content).not_to match('embargoReleaseDate')
    end

    it 'embargo metadata changes to status released after Dor::Item.release_embargo' do
      expect(item.embargoMetadata.ng_xml.at_xpath('//status').text).to eql 'embargoed'
      item.release_embargo('ignored')
      expect(item.embargoMetadata.ng_xml.at_xpath('//status').text).to eql 'released'
    end
  end

  # TODO: #release_embargo is a method on Dor::Item (dor-services). The test should be moved there.
  context 'release_20_pct_vis_embargo' do
    let(:embargo_twenty_pct_xml) {
      <<-EOXML
      <embargoMetadata>
        <status>embargoed</status>
        <releaseDate>#{embargo_release_date.iso8601}</releaseDate>
        <twentyPctVisibilityStatus>anything</twentyPctVisibilityStatus>
        <twentyPctVisibilityReleaseDate>#{embargo_release_date.iso8601}</twentyPctVisibilityReleaseDate>
        #{release_access}
      </embargoMetadata>
      EOXML
    }
    let(:item) {
      i = Dor::Item.new
      rds = Dor::RightsMetadataDS.new
      rds.content = Nokogiri::XML(rights_xml) { |config| config.default_xml.noblanks }.to_s
      i.datastreams['rightsMetadata'] = rds
      eds = Dor::EmbargoMetadataDS.new
      eds.content = Nokogiri::XML(embargo_twenty_pct_xml) { |config| config.default_xml.noblanks }.to_s
      i.datastreams['embargoMetadata'] = eds
      i
    }

    it 'rights metadata has no embargo after Dor::Item.release_20_pct_vis_embargo' do
      expect(item.rightsMetadata.ng_xml.at_xpath('//embargoReleaseDate')).not_to be_nil
      expect(item.rightsMetadata.content).to match('embargoReleaseDate')
      item.release_20_pct_vis_embargo('ignored')
      expect(item.rightsMetadata.ng_xml.at_xpath('//embargoReleaseDate')).to be_nil
      expect(item.rightsMetadata.content).not_to match('embargoReleaseDate')
    end

    it 'embargo metadata changes to twenty_pct_status released after Dor::Item.release_20_pct_vis_embargo' do
      expect(item.embargoMetadata.twenty_pct_status).to eql 'anything'
      item.release_20_pct_vis_embargo('ignored')
      expect(item.embargoMetadata.twenty_pct_status).to eql 'released'
    end
  end

  describe '.release_items' do
    subject(:release_items) { Robots::DorRepo::Accession::EmbargoRelease.release_items(query, &block) }

    before do
      # TODO: just requiring the code runs the code, so we have to do some gymnastics to prevent it from running.
      allow(Dor::SearchService).to receive(:query).and_return('response' => { 'numFound' => 0 })
      require_relative '../../../robots/dor_repo/accession/embargo_release'
    end

    let(:block) { proc {} }
    let(:query) { "foo" }
    let(:response) do
      { 'response' => { 'numFound' => 1, 'docs' => [{ 'id' => 'druid:999' }] } }
    end

    before do
      expect(Dor::SearchService).to receive(:query).and_return(response)
    end

    context 'when the object is not in fedora' do
      before do
        allow(Dor).to receive(:find).and_raise(StandardError, "Not Found")
      end

      it "handles the error" do
        expect(LyberCore::Log).to receive(:error).with(/!!! Unable to release embargo for: druid:999\n#<StandardError: Not Found>/)
        expect(Dor::Config.workflow.client).to receive(:update_workflow_error_status)
        release_items
      end
    end

    context 'when the object is in fedora' do
      let(:item) {
        i = Dor::Item.new
        rds = Dor::RightsMetadataDS.new
        rds.content = Nokogiri::XML(rights_xml) { |config| config.default_xml.noblanks }.to_s
        i.datastreams['rightsMetadata'] = rds
        eds = Dor::EmbargoMetadataDS.new
        eds.content = Nokogiri::XML(embargo_xml) { |config| config.default_xml.noblanks }.to_s
        i.datastreams['embargoMetadata'] = eds
        i
      }

      let(:embargo_xml) {
        <<-EOXML
        <embargoMetadata>
          <status>embargoed</status>
          <releaseDate>#{embargo_release_date.iso8601}</releaseDate>
          <twentyPctVisibilityStatus/>
          <twentyPctVisibilityReleaseDate/>
          #{release_access}
        </embargoMetadata>
        EOXML
      }

      before do
        allow(Dor).to receive(:find).and_return(item)
        allow(item).to receive(:save)
        stub_request(:post, "https://example.com/v1/objects/druid:999/versions")
          .to_return(status: 200, body: "3", headers: {})
        stub_request(:post, "https://example.com/v1/objects/druid:999/versions/current/close")
          .with(
            body: "{\"description\":\"embargo released\",\"significance\":\"admin\"}"
          )
          .to_return(status: 200, body: "", headers: {})
        allow(LyberCore::Log).to receive(:info)
      end

      it 'is successful' do
        release_items
        expect(LyberCore::Log).to have_received(:info).with("Done! Processed 1 objects out of 1")
      end
    end
  end
end
