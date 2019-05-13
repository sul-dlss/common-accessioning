# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::EndAccession do
  let(:object) { instance_double(Dor::Item, admin_policy_object: apo) }
  let(:apo) { Dor::AdminPolicyObject.new }
  let(:druid) { 'druid:oo000oo0001' }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil) }

  subject(:robot) { described_class.new }

  before do
    allow(Dor).to receive(:find).with(druid).and_return(object)
    allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    it 'kicks off dissemination' do
      perform
      expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'disseminationWF')
    end
  end
end
