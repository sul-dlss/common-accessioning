# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Assembly::AccessioningInitiate do
  subject(:robot) { described_class.new }

  let(:bare_druid) { 'bb222cc3333' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:process_response) { instance_double(Dor::Services::Response::Process, lane_id: 'high') }
  let(:workflow_response) { instance_double(Dor::Services::Response::Workflow, process_for_recent_version: process_response) }
  let(:object_workflow) { instance_double(Dor::Services::Client::ObjectWorkflow, find: workflow_response) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client, find: object) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(object_client).to receive(:workflow).with('assemblyWF').and_return(object_workflow)
  end

  context 'when the type is item' do
    let(:object) { build(:dro, id: druid) }

    it 'closes the version' do
      test_perform(robot, druid)
      expect(version_client).to have_received(:close).with(lane_id: 'high')
    end
  end

  context 'when the type is collection' do
    let(:object) { build(:collection, id: druid) }

    it 'closes the version' do
      test_perform(robot, druid)
      expect(version_client).to have_received(:close).with(lane_id: 'high')
    end
  end
end
