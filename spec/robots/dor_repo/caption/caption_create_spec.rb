# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Caption::CaptionCreate do
  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }

  it 'runs the start caption robot' do
    expect(test_perform(robot, druid)).to be true
  end
end
