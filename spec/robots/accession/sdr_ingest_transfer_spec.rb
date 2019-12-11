# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::SdrIngestTransfer do
  subject(:robot) { described_class.new }

  let(:druid) { 'druid:aa222cc3333' }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    preserve: 'http://dor-services/background-job/123')
  end

  describe '#perform' do
    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    end

    it 'is successful' do
      robot.perform(druid)
      expect(object_client).to have_received(:preserve)
    end
  end
end
