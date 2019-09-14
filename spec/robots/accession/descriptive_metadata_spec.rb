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
        allow(object).to receive(:descMetadata).and_return(Dor::DescMetadataDS.new)
        allow(Dor).to receive(:find).and_return(object)

        expect { perform }.to raise_error(RuntimeError, "#{druid} descMetadata missing required fields (<title>)")
      end

      it 'does not raise error if descMetadata has a mods_title value' do
        mock_desc_md_ds = instance_double(Dor::DescMetadataDS, dsid: 'descMetadata', new?: false, content: '', save: true, mods_title: 'anything')
        allow(object).to receive(:descMetadata).and_return(mock_desc_md_ds)
        allow(Dor).to receive(:find).and_return(object)

        expect { perform }.not_to raise_error
      end

      it 'reloads the Dor object if it makes remote service call' do
        allow(object.descMetadata).to receive(:mods_title).and_return('anything')
        perform
        expect(object_client).to have_received(:refresh_metadata)
        expect(Dor).to have_received(:find).with(druid).twice
      end
    end
  end
end
