# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::ContentMetadata do
  subject(:robot) { described_class.new }

  describe '.perform' do
    subject(:perform) { robot.perform(druid) }
    before do
      allow(Dor).to receive(:find).and_return(object)
    end
    let(:druid) { 'druid:bd185gs2259' }
    let(:object) { Dor::Item.new(pid: druid) }
    let(:builder) { instance_double(DatastreamBuilder, build: true) }

    it 'builds a datastream' do
      expect(DatastreamBuilder).to receive(:new)
        .with(datastream: Dor::ContentMetadataDS,
              force: true,
              object: object).and_return(builder)
      expect(builder).to receive(:build)
      perform
    end
  end
end
