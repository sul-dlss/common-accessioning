# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::DescriptiveMetadata do
  subject(:robot) { described_class.new }

  it 'includes behavior from LyberCore::Robot' do
    expect(robot.methods).to include(:work)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    let(:druid) { 'druid:ab123cd4567' }

    context 'on an item' do
      let(:object_client) { instance_double(Dor::Services::Client::Object, refresh_metadata: true) }

      before do
        stub_request(:get, 'https://example.com/workflow/objects/druid:ab123cd4567/workflows')
          .to_return(status: 200, body: '', headers: {})
        stub_request(:get, 'https://example.com/workflow/dor/objects/druid:ab123cd4567/lifecycle')
          .to_return(status: 200, body: '', headers: {})

        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
        allow(Dor).to receive(:find).and_return(object)
      end

      let!(:object) { Dor::Item.create!(pid: druid, catkey: '12345') }

      it 'builds a datastream from the remote service call' do
        allow(object.descMetadata).to receive(:mods_title).and_return('anything')
        perform
        expect(object_client).to have_received(:refresh_metadata)
      end

      it 'raises error if descMetadata mods has no <title>' do
        mods = <<-EOXML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <recordInfo>
            <recordIdentifier source="SIRSI">a13132918</recordIdentifier>
            <recordOrigin>Converted from MARCXML to MODS version 3.6 using MARC21slim2MODS3-6_SDR.xsl (SUL version 1 2018/06/13; LC Revision 1.118 2018/01/31)</recordOrigin>
          </recordInfo>
        </mods>
        EOXML
        mock_desc_md_ds = instance_double('datastream', dsid: 'descMetadata', new?: false, content: mods, save: true, mods_title: '')
        allow(object).to receive(:descMetadata).and_return(mock_desc_md_ds)
        allow(Dor).to receive(:find).and_return(object)

        expect { perform }.to raise_error(RuntimeError, 'descMetadata missing required fields (<title>)')
      end
    end
  end
end
