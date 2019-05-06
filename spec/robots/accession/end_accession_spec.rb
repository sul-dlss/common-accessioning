# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::EndAccession do
  let(:object) { Dor::Item.new }
  let(:apo) { Dor::AdminPolicyObject.new }
  let(:druid) { 'druid:oo000oo0001' }
  subject(:robot) { described_class.new }

  before do
    allow(Dor).to receive(:find).with(druid).and_return(object)
    allow(object).to receive(:admin_policy_object).and_return(apo)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    it 'kicks off dissemination' do
      expect(object).to receive(:initialize_workflow).with('disseminationWF')
      perform
    end
  end
end
