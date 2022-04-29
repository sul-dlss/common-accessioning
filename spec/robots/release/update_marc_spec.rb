# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Release::UpdateMarc do
  let(:druid) { 'bb222cc3333' }
  let(:robot) { described_class.new }

  it 'posts to the update marc record api' do
    stub_request(:post, 'https://dor-services-test.stanford.test/v1/objects/bb222cc3333/update_marc_record')
      .to_return(status: 201, body: '', headers: {})
    robot.perform(druid)
  end
end
