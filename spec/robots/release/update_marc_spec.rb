# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Release::UpdateMarc do
  let(:druid) { 'bb222cc3333' }
  let(:robot) { described_class.new }

  before do
    stub_request(:post, 'https://dor-services-test.stanford.test/v1/objects/bb222cc3333/update_marc_record')
      .to_return(status: 201, body: '', headers: {})
  end

  it 'posts to the update marc record api' do
    # NOTE: Until I wrapped the `#perform` call in the `expect...not_to raise_error`,
    #       there were no expectations in this spec. What do we *really* expect here?
    expect { test_perform(robot, druid) }.not_to raise_error
  end

  it 'returns a noop ReturnState' do
    result = test_perform(robot, druid)
    expect(result).to be_a(LyberCore::ReturnState)
    expect(result.status).to eq('noop')
    expect(result.note).to eq('Initiated update_marc_record API call.')
  end
end
