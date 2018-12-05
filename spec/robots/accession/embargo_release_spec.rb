# frozen_string_literal: true

require 'spec_helper'

describe 'embargo_release.rb' do
  Dor.configure do
    workflow.url 'http://example.org/workflow'
  end

  before(:each) do
    allow_any_instance_of(RSolr::Client).to receive(:get) {
      {
        'response' => {
          'numFound' => '1',
          'docs' => {}
        }
      }
    }
    # must do require after mocking Solr call because loading the file calls method
    require File.expand_path(File.dirname(__FILE__) + '/../../../robots/accession/embargo_release')
  end

  let(:embargo_release_date) { Time.now.utc - 100000 }

  let(:release_access) { <<-EOXML
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

  let(:rights_xml) { <<-EOXML
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

  context "release_embargo" do
    let(:embargo_xml) { <<-EOXML
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
      rds.content = Nokogiri::XML(rights_xml) {|config| config.default_xml.noblanks}.to_s
      i.datastreams['rightsMetadata'] = rds
      eds = Dor::EmbargoMetadataDS.new
      eds.content = Nokogiri::XML(embargo_xml) {|config| config.default_xml.noblanks}.to_s
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

  context 'release_20_pct_vis_embargo' do
    let(:embargo_twenty_pct_xml) { <<-EOXML
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
      rds.content = Nokogiri::XML(rights_xml) {|config| config.default_xml.noblanks}.to_s
      i.datastreams['rightsMetadata'] = rds
      eds = Dor::EmbargoMetadataDS.new
      eds.content = Nokogiri::XML(embargo_twenty_pct_xml) {|config| config.default_xml.noblanks}.to_s
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

  it 'attempts to run EmbargoRelease.release' do
    skip('difficult to test, need to include file to set expectation, but including file executes method call to be tested.  right thing to do would be to refactor into class def file and script execution file.')
  end
end
