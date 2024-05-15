# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Ocr::OcrCreate do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }

  it 'runs the OCR create robot' do
    expect(perform.status).to eq 'noop'
  end
end
