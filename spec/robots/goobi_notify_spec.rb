# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Goobi::GoobiNotify do
  it 'makes the web service call to notify goobi' do
    druid = 'druid:aa222cc3333'
    stub_request(:post, "https://example.com/v1/objects/#{druid}/notify_goobi")
      .with(headers: { 'Accept' => '*/*',
                       'Authorization' => 'Basic VVNFUk5BTUU6UEFTU1dPUkQ=',
                       'Content-Length' => '0' })
      .to_return(status: 200, body: '', headers: {})
    r = described_class.new
    response = r.perform(druid)
    expect(response).to be true
  end
end
