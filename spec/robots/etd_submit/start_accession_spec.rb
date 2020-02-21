# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::EtdSubmit::StartAccession do
  subject(:robot) { described_class.new }

  describe '#perform' do
    let(:druid) { 'druid:mj151qw9093' }
    let(:process) { instance_double(Dor::Workflow::Response::Process, lane_id: 'default') }
    let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil, process: process) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client) }
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, current: '1') }

    before do
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    it 'invokes Dor::Workflow::Client with druid and workflow name' do
      robot.perform(druid)
      expect(workflow_client).to have_received(:create_workflow_by_name)
        .with(druid, 'accessionWF', version: '1', lane_id: 'default')
    end
  end
end
