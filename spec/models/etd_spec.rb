# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Etd do
  subject(:etd) { described_class.new(pid: druid) }
  let(:druid) { 'druid:ab123cd4567' }

  describe '.find' do
    before do
      allow(etd.workflows).to receive(:content).and_return('')
      etd.identityMetadata.objectType = 'item'
      etd.save!
    end
    it 'loads the object as an Etd' do
      expect(described_class.find(druid)).to be_kind_of Etd
    end
  end

  describe '#populate_datastream' do
    subject(:populate) { etd.populate_datastream(ds_name) }

    context 'when called on rightsMetadata' do
      let(:ds_name) { 'rightsMetadata' }
      before do
        allow(Dor::Etd::RightsMetadataGenerator).to receive(:generate)
      end
      it 'calls the generator' do
        populate
        expect(Dor::Etd::RightsMetadataGenerator).to have_received(:generate).with(etd)
      end
    end
  end

  describe '#generate_content_metadata_xml' do
    subject(:generate) { etd.generate_content_metadata_xml }

    let(:main_pdf) { Part.new }
    let(:druid_tool) { instance_double(DruidTools::Druid, content_dir: '/foo/bar') }
    let(:properties_ds) { double('custom properties', file_name: ['project.pdf']) }
    let(:md5_digest) { instance_double(Digest::MD5, hexdigest: '123abcdef') }
    let(:sha1_digest) { instance_double(Digest::SHA1, hexdigest: '123abcdef') }

    before do
      allow(main_pdf).to receive(:datastreams).and_return('properties' => properties_ds)
      allow(DruidTools::Druid).to receive(:new).and_return(druid_tool)
      allow(etd).to receive(:parts).and_return([main_pdf])
      allow(properties_ds).to receive(:term_values).with(:size).and_return([9])
      allow(Digest::MD5).to receive(:file).with('/foo/bar/project.pdf').and_return(md5_digest)
      allow(Digest::SHA1).to receive(:file).with('/foo/bar/project.pdf').and_return(sha1_digest)
      allow(Digest::MD5).to receive(:file).with('/foo/bar/project-augmented.pdf').and_return(md5_digest)
      allow(Digest::SHA1).to receive(:file).with('/foo/bar/project-augmented.pdf').and_return(sha1_digest)
    end

    it 'generates xml' do
      expect(generate).to be_equivalent_to <<~XML
        <contentMetadata type="file" objectId="druid:ab123cd4567">
          <resource id="ab123cd4567_1" type="main-original">
            <attr name="label">Body of dissertation (as submitted)</attr>
            <file id="project.pdf" mimetype="application/pdf" size="9" shelve="yes" publish="no" preserve="yes">
              <checksum type="md5">123abcdef</checksum>
              <checksum type="sha1">123abcdef</checksum>
            </file>
          </resource>
          <resource id="ab123cd4567_2" type="main-augmented" objectId="">
            <attr name="label">Body of dissertation</attr>
            <file id="project-augmented.pdf" mimetype="application/pdf" size="" shelve="yes" publish="yes" preserve="yes">
              <checksum type="md5">123abcdef</checksum>
              <checksum type="sha1">123abcdef</checksum>
            </file>
            </resource>
          </contentMetadata>
      XML
    end
  end
end
