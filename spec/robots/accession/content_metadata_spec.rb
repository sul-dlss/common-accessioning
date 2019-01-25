# frozen_string_literal: true

require 'spec_helper'

require File.expand_path(File.dirname(__FILE__) + '/../../../robots/accession/content_metadata')

RSpec.describe Robots::DorRepo::Accession::ContentMetadata do
  subject(:robot) { described_class.new }

  describe '.perform' do
    subject(:perform) { robot.perform(druid) }
    before do
      allow(Dor).to receive(:find).and_return(object)
    end
    let(:druid) { 'druid:bd185gs2259' }
    let(:object) { Dor::Item.new(pid: druid) }
    let(:builder) { instance_double(Dor::DatastreamBuilder, build: true) }

    it 'builds a datastream' do
      expect(Dor::DatastreamBuilder).to receive(:new)
        .with(datastream: Dor::ContentMetadataDS,
              force: true,
              object: object,
              required: false).and_return(builder)
      expect(builder).to receive(:build)
      perform
    end
  end
end
