# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::ChecksumCompute do
  let(:robot) { described_class.new }
  let(:bare_druid) { 'bb222cc3333' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, find: object)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when the item is a DRO' do
    let(:assembly_item) { Dor::Assembly::Item.new(druid: bare_druid) }
    let(:object) { build(:dro, id: druid) }

    before do
      # Need to load_content_metadata before we can set up expectations on the file_nodes
      assembly_item.load_content_metadata
      allow(robot).to receive(:item).and_return(assembly_item)
    end

    it 'computes checksums' do
      # Prevent writing out the changes
      expect(assembly_item).to receive(:persist_content_metadata)

      # Expectations that the checksums are added as nodes
      expect(assembly_item.file_nodes[0]).to receive(:add_child)
      expect(assembly_item.file_nodes[1]).not_to receive(:add_child)
      expect(assembly_item.file_nodes[2]).to receive(:add_child).twice

      robot.perform(bare_druid)
    end
  end

  context 'when not a DRO' do
    let(:object) { build(:collection, id: druid) }

    it 'does not compute checksums' do
      expect(robot).not_to receive(:compute_checksums)
      robot.perform(bare_druid)
    end
  end
end
