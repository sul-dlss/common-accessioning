# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Etd::VersionMetadataGenerator do
  let(:etd) { Etd.new(pid: druid) }
  let(:druid) { 'druid:ab123cd4567' }

  describe '.generate' do
    subject(:generate) { described_class.generate(etd.pid) }

    it 'generates xml' do
      expect(generate).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
        <versionMetadata objectId="#{druid}">
          <version versionId="1" tag="1.0.0">
            <description>Initial Version</description>
          </version>
        </versionMetadata>
      XML
    end
  end
end
