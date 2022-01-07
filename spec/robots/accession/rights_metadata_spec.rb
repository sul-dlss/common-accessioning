# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::RightsMetadata do
  subject(:perform) { robot.perform(druid) }

  let(:robot) { described_class.new }
  let(:druid) { 'druid:ab123cd4567' }
  let(:apo_id) { 'druid:mx121xx1234' }

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, metadata: metadata_client)
  end
  let(:metadata_client) do
    instance_double(Dor::Services::Client::Metadata, legacy_update: true)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  context 'when no rightsMetadata file is found' do
    it 'skips the step' do
      expect(perform.status).to eq 'skipped'
      expect(metadata_client).not_to have_received(:legacy_update)
    end

    context 'when rightsMetadata file is found' do
      let(:finder) { instance_double(DruidTools::Druid, find_metadata: 'spec/fixtures/ab123cd4567_descMetadata.xml') }

      before do
        allow(DruidTools::Druid).to receive(:new).and_return(finder)
      end

      it 'reads the file in' do
        perform
        expect(metadata_client).to have_received(:legacy_update).with(
          rights: {
            updated: Time,
            content: /first book in Latin/
          }
        )
      end
    end
  end
end
