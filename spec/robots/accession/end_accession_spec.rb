# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::EndAccession do
  subject(:robot) { described_class.new }

  let(:object) { instance_double(Dor::Item, admin_policy_object: apo) }
  let(:apo) { Dor::AdminPolicyObject.new }
  let(:druid) { 'druid:oo000oo0001' }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil) }

  before do
    allow(Dor).to receive(:find).with(druid).and_return(object)
    allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    context 'when there is no special dissemniation workflow' do
      it 'kicks off dissemination' do
        perform
        expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'disseminationWF')
      end
    end

    context 'when there is a special dissemniation workflow' do
      before do
        apo.administrativeMetadata.content = xml
      end

      let(:xml) do
        <<~XML
          <administrativeMetadata>
            <dissemination>
              <workflow id="wasDisseminationWF"/>
            </dissemination>
          </administrativeMetadata>
        XML
      end

      it 'kicks off both dissemination workflows' do
        perform
        expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'wasDisseminationWF')
        expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'disseminationWF')
      end
    end
  end
end
