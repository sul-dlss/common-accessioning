# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::EtdSubmit::OtherMetadata do
  subject(:robot) { described_class.new }

  let(:druid) { 'druid:mj151qw9093' }
  let(:object) { Etd.new(pid: druid) }
  let(:obj_client) { instance_double(Dor::Services::Client::Object, metadata: metadata_obj, refresh_metadata: true) }
  let(:metadata_obj) { instance_double(Dor::Services::Client::Metadata, legacy_update: true) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(obj_client)
  end

  describe '#systemu' do
    # Validate that the stub we use later is valid for this object
    it { is_expected.to respond_to(:systemu) }
  end

  describe '#create_metadata' do
    subject(:create_metadata) { robot.send(:create_metadata, object, druid) }

    before do
      allow(Dor::Etd::ContentMetadataGenerator).to receive(:generate).and_return('<contentMetadata/>')
      allow(Dor::Etd::IdentityMetadataGenerator).to receive(:generate).and_return('<identityMetadata/>')
      allow(Dor::Etd::RightsMetadataGenerator).to receive(:generate).and_return('<rightsMetadata/>')
      allow(Dor::Etd::VersionMetadataGenerator).to receive(:generate).and_return('<versionMetadata/>')
      create_metadata
    end

    it 'calls the generators' do
      expect(Dor::Etd::ContentMetadataGenerator).to have_received(:generate).with(object)
      expect(Dor::Etd::IdentityMetadataGenerator).to have_received(:generate).with(object)
      expect(Dor::Etd::RightsMetadataGenerator).to have_received(:generate).with(object)
      expect(Dor::Etd::VersionMetadataGenerator).to have_received(:generate).with(object.pid)
    end

    it 'calls legacy_metadata with the correct data' do
      expect(metadata_obj).to have_received(:legacy_update)
        .with(hash_including(
                content: hash_including(:updated, content: '<contentMetadata/>'),
                identity: hash_including(:updated, content: '<identityMetadata/>'),
                rights: hash_including(:updated, content: '<rightsMetadata/>'),
                version: hash_including(:updated, content: '<versionMetadata/>')
              ))
    end
  end

  describe '#perform' do
    let(:druid_tools) { instance_double(DruidTools::Druid, content_dir: '/foo/bar') }
    let(:status) { instance_double(Process::Status, exitstatus: 0) }

    before do
      allow(Etd).to receive(:find).and_return(object)
      allow(robot).to receive(:create_metadata)
      allow(DruidTools::Druid).to receive(:new).and_return(druid_tools)
      allow(robot).to receive(:systemu).and_return([status, nil, nil])
      allow(File).to receive(:exist?).with('/foo/bar').and_return(true)
    end

    it 'creates the metadata' do
      robot.perform(druid)
      expect(robot).to have_received(:create_metadata).with(object, druid)
    end
  end
end
