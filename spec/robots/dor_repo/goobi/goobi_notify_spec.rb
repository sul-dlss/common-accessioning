# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Goobi::GoobiNotify do
  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }

  before do
    stub_request(:post, "https://dor-services-test.stanford.test/v1/objects/#{druid}/notify_goobi")
      .with(headers: { 'Accept' => '*/*',
                       'Authorization' => 'Bearer secret-token',
                       'Content-Length' => '0' })
      .to_return(status: 200, body: '', headers: {})
  end

  it 'makes the web service call to notify goobi' do
    expect(test_perform(robot, druid)).to be true
  end
end
