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
    let(:builder) { instance_double(DatastreamBuilder, build: true) }

    context 'on an item' do
      let(:object) { Dor::Item.new(pid: druid) }

      it 'builds a datastream' do
        expect(DatastreamBuilder).to receive(:new)
          .with(datastream: Dor::ContentMetadataDS,
                force: true,
                object: object).and_return(builder)
        expect(builder).to receive(:build)
        perform
      end
    end

    context 'on a collection' do
      let(:object) { Dor::Collection.new(pid: druid) }

      it "doesn't make a datastream" do
        expect(DatastreamBuilder).not_to receive(:new)
        perform
      end
    end
  end
end
