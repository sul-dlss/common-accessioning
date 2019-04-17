# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::RightsMetadata do
  let(:robot) { described_class.new }

  let(:item) do
    instantiate_fixture('druid:ab123cd4567', Dor::Item)
  end

  describe '#build_datastream' do
    let(:apo) { instantiate_fixture('druid:fg890hi1234', Dor::AdminPolicyObject) }
    let(:rights_md) { apo.defaultObjectRights.content }

    before do
      allow(item).to receive(:admin_policy_object).and_return(apo)
    end

    it 'copies the default object rights' do
      expect(item.rightsMetadata.ng_xml.to_s).not_to be_equivalent_to(rights_md)
      robot.send(:build_datastream, item, item.rightsMetadata)
      expect(item.rightsMetadata.ng_xml.to_s).to be_equivalent_to(rights_md)
    end
  end
end
