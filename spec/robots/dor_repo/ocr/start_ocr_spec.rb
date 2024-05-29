# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Ocr::StartOcr do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }

  let(:object) { build(:dro, id: druid) }
  let(:workspace_client) { instance_double(Dor::Services::Client::Workspace) }
  let(:version_client) do
    instance_double(Dor::Services::Client::ObjectVersion, open: true,
                                                          status: instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: version_open))
  end
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, workspace: workspace_client, find: object)
  end
  let(:ocr) do
    instance_double(Dor::TextExtraction::Ocr, possible?: possible)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Dor::TextExtraction::Ocr).to receive(:new).and_return(ocr)
  end

  context 'when the object is not opened and is possible to OCR' do
    let(:version_open) { false }
    let(:possible) { true }

    it 'opens the object' do
      perform
      expect(version_client).to have_received(:open)
    end
  end

  context 'when the object is not opened and is not possible to OCR' do
    let(:version_open) { false }
    let(:possible) { false }

    it 'raise an error' do
      expect { perform }.to raise_error('No files available or invalid object for OCR')
    end
  end

  context 'when the object is already opened' do
    let(:version_open) { true }
    let(:possible) { true }

    it 'raises an error' do
      expect { perform }.to raise_error('Object is already open')
    end
  end
end
