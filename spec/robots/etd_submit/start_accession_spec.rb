# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::EtdSubmit::StartAccession do
  subject(:robot) { described_class.new }

  describe '#perform' do
    let(:druid) { 'druid:mj151qw9093' }
    let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil) }

    before do
      allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
    end

    it 'invokes Dor::Workflow::Client with druid and workflow name' do
      robot.perform(druid)
      expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'accessionWF')
    end
  end
end
