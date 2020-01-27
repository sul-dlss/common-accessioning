# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::RightsMetadata do
  subject(:perform) { robot.perform(druid) }

  let(:robot) { described_class.new }
  let(:druid) { 'druid:ab123cd4567' }

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, refresh_metadata: true, metadata: metadata_client)
  end
  let(:metadata_client) do
    instance_double(Dor::Services::Client::Metadata, legacy_update: true)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when no rightsMetadata file is found' do
    before do
      allow(Dor).to receive(:find).and_return(fedora_obj)
    end

    let(:fedora_obj) { instance_double(Dor::Item, rightsMetadata: datastream, admin_policy_object: apo) }
    let(:apo) { instance_double(Dor::AdminPolicyObject, defaultObjectRights: default_ds) }
    let(:default_ds) { instance_double(Dor::DefaultObjectRightsDS, content: 'this is default') }

    context "when rightsMetadata doesn't exist" do
      let(:datastream) { instance_double(Dor::RightsMetadataDS, new?: true) }

      it 'builds a datastream from the remote service call' do
        perform
        expect(metadata_client).to have_received(:legacy_update)
      end
    end

    context 'when rightsMetadata exists' do
      let(:datastream) { instance_double(Dor::RightsMetadataDS, new?: false) }

      it 'does nothing' do
        perform
        expect(metadata_client).not_to have_received(:legacy_update)
      end
    end
  end

  context 'when rightsMetadata file is found' do
    let(:finder) { instance_double(DruidTools::Druid, find_metadata: 'spec/fixtures/ab123cd4567_descMetadata.xml') }

    before do
      allow(DruidTools::Druid).to receive(:new).and_return(finder)
    end

    # rubocop:disable RSpec/ExampleLength
    it 'reads the file in' do
      perform
      expect(metadata_client).to have_received(:legacy_update).with(
        rights: {
          updated: Time,
          content: /first book in Latin/
        }
      )
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
