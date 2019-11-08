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

      let(:desc_md) do
        instance_double(Dor::DescMetadataDS, pid: druid, mods_title: nil, dsid: 'descMetadata', new?: true, save: true)
      end

      let!(:object) do
        instance_double(Dor::Item, catkey: '12345', reload: true, descMetadata: desc_md)
      end

      context 'when descMetadata mods has no <title>' do
        it 'raises error' do
          expect { perform }.to raise_error(RuntimeError, "#{druid} descMetadata missing required fields (<title>)")
        end
      end

      context 'when descMetadata has a mods_title value' do
        let(:desc_md) do
          instance_double(Dor::DescMetadataDS, pid: druid, mods_title: 'anything', dsid: 'descMetadata', new?: true, save: true)
        end

        it 'does not raise error' do
          expect { perform }.not_to raise_error
        end

        it 'builds a datastream from the remote service call' do
          perform
          expect(object_client).to have_received(:refresh_metadata)
        end
      end

      it 'reloads the Dor object' do
        allow(object.descMetadata).to receive(:mods_title).and_return('anything')
        allow(object).to receive(:reload)
        perform
        expect(object_client).to have_received(:refresh_metadata)
        expect(object).to have_received(:reload)
      end
    end
  end
end
