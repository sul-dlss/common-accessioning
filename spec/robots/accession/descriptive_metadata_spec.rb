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

    before do
      allow(Dor).to receive(:find).and_return(object)
    end

    let(:builder) { instance_double(DatastreamBuilder, build: true) }

    context 'on an item' do
      let(:object) { Dor::Item.new(pid: druid) }

      it 'builds a datastream' do
        expect(DatastreamBuilder).to receive(:new)
          .with(datastream: Dor::DescMetadataDS,
                required: true,
                object: object).and_return(builder)
        expect(builder).to receive(:build)
        perform
      end
    end
  end
end
