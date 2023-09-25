# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::SdrIngestTransfer do
  subject(:robot) { described_class.new }

  let(:druid) { 'druid:bb222cc3333' }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    preserve: 'http://dor-services/background-job/123')
  end
  let(:process) do
    instance_double(Dor::Workflow::Response::Process, lane_id: 'low')
  end

  describe '#perform' do
    subject(:perform) { test_perform(robot, druid) }

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
      allow(robot.workflow_service).to receive(:process).and_return(process)
    end

    it 'is successful' do
      expect(perform.status).to eq 'noop'
      expect(object_client).to have_received(:preserve).with(lane_id: 'low')
    end
  end
end
