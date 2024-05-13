# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Ocr::OcrCreate do
  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }

  it 'runs the OCR create robot' do
    expect(test_perform(robot, druid)).to be_a(LyberCore::ReturnState)
  end
end