# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::Ocr::StageFiles do
  let(:druid) { 'druid:bb222cc3333' }
  let(:robot) { described_class.new }

  let(:workspace_client) do
    instance_double(Dor::Services::Client::Workspace, create: '/fake/dor/workspace')
  end

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, workspace: workspace_client)
  end

  let(:results) do
    instance_double(Dor::TextExtraction::Abbyy::Results, move_result_files: true)
  end

  context 'when there are files to move' do
    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
      allow(Dor::TextExtraction::Abbyy::Results)
        .to receive(:find_latest)
        .with(hash_including(druid:))
        .and_return(results)
    end

    it 'runs the stage files robot' do
      expect(test_perform(robot, druid)).to be true
      expect(results).to have_received(:move_result_files).with('/fake/dor/workspace/content')
    end
  end
end
