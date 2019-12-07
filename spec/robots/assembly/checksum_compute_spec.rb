# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::ChecksumCompute do
  let(:robot) { described_class.new(druid: druid) }
  let(:druid) { 'aa222cc3333' }

  context 'when type=item' do
    let(:assembly_item) { setup_assembly_item(druid, :item) }

    before do
      # Need to load_content_metadata before we can set up expectations on the file_nodes
      assembly_item.load_content_metadata
    end

    it 'computes checksums' do
      # Prevent writing out the changes
      expect(assembly_item).to receive(:persist_content_metadata)

      # Expectations that the checksums are added as nodes
      expect(assembly_item.file_nodes[0]).to receive(:add_child)
      expect(assembly_item.file_nodes[1]).not_to receive(:add_child)
      expect(assembly_item.file_nodes[2]).to receive(:add_child).twice

      robot.perform(assembly_item)
    end
  end

  context 'when type=set' do
    let(:assembly_item) { setup_assembly_item(druid, :set) }

    it 'does not compute checksums' do
      expect(assembly_item).not_to be_item
      expect(assembly_item).not_to receive(:load_content_metadata)
      expect(robot).not_to receive(:compute_checksums)
      robot.perform(assembly_item)
    end
  end
end
