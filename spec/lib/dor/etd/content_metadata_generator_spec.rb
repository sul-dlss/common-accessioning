# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Etd::ContentMetadataGenerator do
  let(:etd) { Etd.new(pid: druid) }
  let(:druid) { 'druid:ab123cd4567' }
  let(:main_pdf) { Part.new }

  before do
    allow(main_pdf).to receive(:file_name).and_return('project.pdf')
    allow(main_pdf).to receive(:size).and_return('9')

    allow(etd).to receive(:parts).and_return([main_pdf])
  end

  describe '.generate' do
    subject(:generate) { described_class.generate(etd) }

    let(:druid_tool) { instance_double(DruidTools::Druid, content_dir: '/foo/bar') }
    let(:md5_digest) { instance_double(Digest::MD5, hexdigest: '123abcdef') }
    let(:sha1_digest) { instance_double(Digest::SHA1, hexdigest: '123abcdef') }

    before do
      allow(DruidTools::Druid).to receive(:new).and_return(druid_tool)
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
