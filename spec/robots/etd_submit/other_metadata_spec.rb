# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::EtdSubmit::OtherMetadata do
  subject(:robot) { described_class.new }

  let(:druid) { 'druid:mj151qw9093' }
  let(:object) { Etd.new(pid: druid) }

  describe '#systemu' do
    # Validate that the stub we use later is valid for this object
    it { is_expected.to respond_to(:systemu) }
  end

  describe '#populate_datastream' do
    subject(:populate) { robot.populate_datastream(object, ds_name) }

    context 'when called on rightsMetadata' do
      let(:ds_name) { 'rightsMetadata' }

      before do
        allow(Dor::Etd::RightsMetadataGenerator).to receive(:generate)
      end

      it 'calls the generator' do
        populate
        expect(Dor::Etd::RightsMetadataGenerator).to have_received(:generate).with(object)
      end
    end
  end

  describe '#perform' do
    let(:druid_tools) { instance_double(DruidTools::Druid, content_dir: '/foo/bar') }
    let(:status) { instance_double(Process::Status, exitstatus: 0) }

    before do
      allow(Etd).to receive(:find).and_return(object)
      allow(robot).to receive(:populate_datastream)
      allow(DruidTools::Druid).to receive(:new).and_return(druid_tools)
      allow(robot).to receive(:systemu).and_return([status, nil, nil])
      allow(File).to receive(:exist?).with('/foo/bar').and_return(true)
    end

    it 'populates the datastreams' do
      robot.perform(druid)
      expect(robot).to have_received(:populate_datastream).with(object, 'contentMetadata')
      expect(robot).to have_received(:populate_datastream).with(object, 'rightsMetadata')
      expect(robot).to have_received(:populate_datastream).with(object, 'identityMetadata')
      expect(robot).to have_received(:populate_datastream).with(object, 'versionMetadata')
    end
  end
end
