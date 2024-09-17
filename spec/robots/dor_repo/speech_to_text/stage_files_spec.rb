# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::SpeechToText::StageFiles do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }

  it 'runs the stage-files robot' do
    expect(perform).to be true
  end
end
