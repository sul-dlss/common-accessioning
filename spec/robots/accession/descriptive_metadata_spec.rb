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
    let(:object_client) do
      instance_double(Dor::Services::Client::Object, metadata: metadata_client)
    end
    let(:metadata_client) do
      instance_double(Dor::Services::Client::Metadata, update_mods: nil)
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    context 'when no descMetadata file is found' do
      it 'builds a datastream from the remote service call' do
        expect(perform.status).to eq 'skipped'
        expect(metadata_client).not_to have_received(:update_mods)
      end
    end

    context 'when descMetadata file is found' do
      let(:finder) { instance_double(DruidTools::Druid, find_metadata: 'spec/fixtures/ab123cd4567_descMetadata.xml') }

      before do
        allow(DruidTools::Druid).to receive(:new).and_return(finder)
      end

      it 'reads the file in' do
        perform
        expect(metadata_client).to have_received(:update_mods).with(/first book in Latin/)
      end
    end
  end
end
