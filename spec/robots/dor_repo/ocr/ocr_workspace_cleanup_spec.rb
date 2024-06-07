# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Ocr::OcrWorkspaceCleanup do
  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }

  let(:object) { build(:dro, id: druid) }
  let(:ocr) do
    instance_double(Dor::TextExtraction::Ocr, cleanup: true)
  end
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, find: object)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Dor::TextExtraction::Ocr).to receive(:new).and_return(ocr)
  end

  it 'calls the cleanup method' do
    test_perform(robot, druid)
    expect(ocr).to have_received(:cleanup)
  end
end
