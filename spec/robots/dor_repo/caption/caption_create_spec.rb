# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Caption::CaptionCreate do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }

  it 'runs the start caption robot' do
    expect(perform.status).to eq 'noop'
  end
end
