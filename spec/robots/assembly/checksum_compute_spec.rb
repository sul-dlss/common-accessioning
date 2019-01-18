# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Assembly::ChecksumCompute do
  before :each do
    @druid = 'aa222cc3333'
    allow(Dor::Assembly::Item).to receive(:new).and_return(@assembly_item)
    @r = Robots::DorRepo::Assembly::ChecksumCompute.new(druid: @druid)
  end

  it 'should compute checksums for type=item' do
    setup_assembly_item(@druid, :item)
    expect(@assembly_item).to be_item
    expect(@assembly_item).to receive(:load_content_metadata)
    expect(@assembly_item).to receive(:compute_checksums)
    @r.perform(@assembly_item)
  end

  it 'should not compute checksums for type=set if configured that way' do
    Dor::Config.configure.assembly.items_only = true
    setup_assembly_item(@druid, :set)
    expect(@assembly_item).not_to be_item
    expect(@assembly_item).not_to receive(:load_content_metadata)
    expect(@assembly_item).not_to receive(:compute_checksums)
    @r.perform(@assembly_item)
  end

  it 'should compute checksums for type=set if configured that way' do
    Dor::Config.configure.assembly.items_only = false
    setup_assembly_item(@druid, :set)
    expect(@assembly_item).not_to receive(:item?)
    expect(@assembly_item).to receive(:load_content_metadata)
    expect(@assembly_item).to receive(:compute_checksums)
    @r.perform(@assembly_item)
  end
end
