# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::EtdSubmit::StartAccession do
  subject(:robot) { described_class.new }

  describe '#perform' do
    let(:druid) { 'druid:mj151qw9093' }
    let(:mock_workflow_instance) { instance_double(Dor::Services::Client::Workflow, create: nil) }

    before do
      allow(Dor::Services::Client.object(druid)).to receive(:workflow).and_return(mock_workflow_instance)
    end

    it 'invokes Dor::Services::Client with druid and workflow name' do
      robot.perform(druid)
      expect(mock_workflow_instance).to have_received(:create).with(wf_name: 'accessionWF')
    end
  end
end
