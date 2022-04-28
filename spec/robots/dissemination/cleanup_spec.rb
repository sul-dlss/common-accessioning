# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Dissemination::Cleanup do
  subject(:robot) { described_class.new }

  let(:druid) { 'druid:bb222cc3333' }

  describe '#perform' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, workspace: workspace_client) }
    let(:workspace_client) { instance_double(Dor::Services::Client::Workspace, cleanup: true) }

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    end

    it 'is successful' do
      robot.perform(druid)
      expect(workspace_client).to have_received(:cleanup)
    end
  end
end
