# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::AccessioningInitiate do
  let(:base_url) { 'http://dor-services.example.edu' }
  let(:druid) { 'aa222cc3333' }
  let(:mock_workflow_instance) { double(create: nil) }
  let(:mock_workspace_instance) { double(create: nil) }

  subject(:robot) { Robots::DorRepo::Assembly::AccessioningInitiate.new(druid: druid) }

  before do
    allow(Dor::Services::Client.object("druid:#{druid}")).to receive(:workflow).and_return(mock_workflow_instance)
    allow(Dor::Services::Client.object("druid:#{druid}")).to receive(:workspace).and_return(mock_workspace_instance)
  end

  context 'when the type is item' do
    before do
      setup_assembly_item(druid, :item)
    end

    it 'initiates accessioning' do
      expect(@assembly_item).to be_item
      robot.perform(@assembly_item)
      expect(mock_workspace_instance).to have_received(:create)
        .with(source: 'spec/test_input2/aa/222/cc/3333')
      expect(mock_workflow_instance).to have_received(:create).with(wf_name: 'accessionWF')
    end
  end

  context 'when the type is set' do
    before do
      setup_assembly_item(druid, :set)
    end

    context 'and items_only is the default' do
      it 'initiates accessioning, but does not initialize the workspace' do
        expect(@assembly_item).not_to be_item
        robot.perform(@assembly_item)
        expect(mock_workspace_instance).not_to have_received(:create)
        expect(mock_workflow_instance).to have_received(:create).with(wf_name: 'accessionWF')
      end
    end

    context 'and items_only is set to false' do
      before do
        Dor::Config.configure.assembly.items_only = false
      end

      it 'initiates accessioning, but does not initialize the workspace' do
        robot.perform(@assembly_item)
        expect(mock_workspace_instance).not_to have_received(:create)
        expect(mock_workflow_instance).to have_received(:create).with(wf_name: 'accessionWF')
      end
    end

    context 'and items_only is set to true' do
      before do
        Dor::Config.configure.assembly.items_only = true
      end

      it 'initiates accessioning, but does not initialize the workspace' do
        robot.perform(@assembly_item)
        expect(mock_workspace_instance).not_to have_received(:create)
        expect(mock_workflow_instance).to have_received(:create).with(wf_name: 'accessionWF')
      end
    end
  end
end
