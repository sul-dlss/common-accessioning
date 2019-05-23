# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Dissemination::Cleanup do
  subject(:robot) { described_class.new }

  let(:druid) { 'druid:aa222cc3333' }

  describe '#perform' do
    before do
      allow(Dor::CleanupService).to receive(:cleanup_by_druid)
    end

    it 'is successful' do
      robot.perform(druid)
      expect(Dor::CleanupService).to have_received(:cleanup_by_druid).with(druid)
    end
  end
end
