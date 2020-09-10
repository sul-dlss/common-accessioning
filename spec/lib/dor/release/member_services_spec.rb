# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Release::MemberService do
  let(:member_service) { described_class.new(druid: 'druid:oo000oo0001') }
  let(:item_member) { Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:xx828xx3282', type: 'item') }
  let(:collection_member) { Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:xx222xx3282', type: 'collection') }
  let(:response) do
    [
      collection_member,
      item_member,
      Dor::Services::Client::Members::Member.new(externalIdentifier: 'druid:xx828xx4444', type: nil)
    ]
  end

  before { allow(member_service).to receive(:members).and_return(response) }

  describe '#sub_collections' do
    it 'returns only the sub collections in the collection' do
      expect(member_service.sub_collections).to eq([collection_member])
    end
  end

  describe '#items' do
    it 'returns only the items in the collection' do
      expect(member_service.items).to eq([item_member])
    end
  end
end
