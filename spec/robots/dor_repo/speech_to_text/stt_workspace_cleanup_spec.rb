# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::SpeechToText::SttWorkspaceCleanup do
  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }

  let(:object) { build(:dro, id: druid) }
  let(:stt) do
    instance_double(Dor::TextExtraction::SpeechToText, cleanup: true)
  end
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, find: object)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Dor::TextExtraction::SpeechToText).to receive(:new).and_return(stt)
  end

  it 'calls the cleanup method' do
    test_perform(robot, druid)
    expect(stt).to have_received(:cleanup)
  end
end
