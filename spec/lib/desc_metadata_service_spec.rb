# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DescMetadataService do
  let(:item) { instantiate_fixture('druid:ab123cd4567', Dor::Item) }

  describe '#build' do
    before do
      stub_request(:get, "#{Dor::Config.metadata.catalog.url}/?barcode=36105049267078").to_return(body: read_fixture('ab123cd4567_descMetadata.xml'))
    end

    it 'calls the catalog service' do
      expect(Dor::MetadataService).to receive(:fetch).with('barcode:36105049267078').and_call_original
      xml = <<-END_OF_XML
       <?xml version="1.0"?>
       <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
         <titleInfo>
           <title/>
         </titleInfo>
       </mods>
      END_OF_XML
      expect(item.datastreams['descMetadata'].ng_xml.to_s).to be_equivalent_to(xml)
      described_class.build(item, item.descMetadata)
      expect(item.datastreams['descMetadata'].ng_xml.to_s).not_to be_equivalent_to(xml)
    end
  end
end
