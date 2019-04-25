# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DatastreamBuilder do
  subject(:builder) do
    described_class.new(object: item, datastream: ds, force: true, required: required)
  end

  let(:required) { false }
  let(:ds) { item.descMetadata }

  describe '#build' do
    subject(:build) do
      builder.build { |ds| DescMetadataService.build(item, ds) }
    end

    # Paths to two files with the same content.
    let(:f1) { 'workspace/ab/123/cd/4567/ab123cd4567/metadata/descMetadata.xml' }
    let(:f2) { 'workspace/ab/123/cd/4567/desc_metadata.xml' }

    let(:dm_filename) { File.join(@fixture_dir, f1) } # Path used inside build_datastream().
    let(:dm_fixture_xml) { read_fixture(f2) } # Path to fixture.
    let(:dm_builder_xml) { dm_fixture_xml.sub(/FROM_FILE/, 'FROM_BUILDER') }

    context 'when operating on an Item' do
      before { item.contentMetadata.content = '<contentMetadata/>' }

      let(:item) { instantiate_fixture('druid:ab123cd4567', Dor::Item) }

      context 'when the datastream exists as a file' do
        let(:time) { Time.now.utc }

        before do
          allow_any_instance_of(described_class).to receive(:find_metadata_file).and_return(dm_filename)
        end

        context 'when the file is newer than datastream' do
          before do
            allow(File).to receive(:mtime).and_return(time)
            allow(item.descMetadata).to receive(:createDate).and_return(time - 99)
          end

          it 'reads content from file' do
            expect { build }.to change { EquivalentXml.equivalent?(item.descMetadata.ng_xml, dm_fixture_xml) }
              .from(false).to(true)
          end
        end

        context 'when the file is older than datastream' do
          before do
            allow(File).to receive(:mtime).and_return(time - 99)
            allow(item.descMetadata).to receive(:createDate).and_return(time)
            allow(DescMetadataService).to receive(:fetch_datastream).and_return(dm_builder_xml)
          end

          it 'file older than datastream: should use the builder' do
            expect { build }.to change { EquivalentXml.equivalent?(item.descMetadata.ng_xml, dm_builder_xml) }
              .from(false).to(true)
          end
        end
      end

      context 'when the datastream does not exist as a file' do
        before do
          allow_any_instance_of(described_class).to receive(:find_metadata_file).and_return(nil)
          allow(DescMetadataService).to receive(:fetch_datastream).and_return(dm_builder_xml)
        end

        it 'uses the datastream method builder' do
          expect { build }.to change { EquivalentXml.equivalent?(item.descMetadata.ng_xml, dm_builder_xml) }
            .from(false).to(true)
        end

        context 'when the datastream is required and not generated' do
          let(:required) { true }
          # fails because the block doesn't build the datastream
          subject(:build) { builder.build { |ds| } }

          it 'raises an exception' do
            expect { build }.to raise_error(RuntimeError)
          end
        end
      end
    end
  end
end
