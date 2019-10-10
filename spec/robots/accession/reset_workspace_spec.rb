# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::ResetWorkspace do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { described_class.new }
  let(:object_client) { instance_double(Dor::Services::Client::Object, workspace: workspace_client) }
  let(:workspace_client) { instance_double(Dor::Services::Client::Workspace, reset: nil) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    before do
      perform
    end

    it 'resets the workspace' do
      expect(workspace_client).to have_received(:reset)
    end
  end
end
