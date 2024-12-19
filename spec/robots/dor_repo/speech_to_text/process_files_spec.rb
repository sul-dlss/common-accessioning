# frozen_string_literal: true

RSpec.describe Robots::DorRepo::SpeechToText::ProcessFiles do
  subject(:perform) { test_perform(robot, druid) }

  include_context 'with workspace dir'

  let(:robot) { described_class.new }

  let(:druid) { 'druid:bb222cc3333' }
  let(:bare_druid) { 'bb222cc3333' }
  let(:mock_filter) { instance_double(Dor::TextExtraction::SpeechToTextFilter) }
  # DruidTools needs to return the workspace_dir set up by "with workspace dir" context
  let(:druid_tools) do
    instance_double(DruidTools::Druid, id: bare_druid, content_dir: workspace_content_dir)
  end

  before do
    allow(DruidTools::Druid).to receive(:new).and_return(druid_tools)
    allow(robot).to receive(:externalIdentifier).and_return(druid)
    allow(Dor::TextExtraction::SpeechToTextFilter).to receive(:new).and_return(mock_filter)
  end

  describe '#perform_work' do
    context 'with text and vtt files' do
      before do
        FileUtils.touch(File.join(workspace_content_dir, 'file1.txt'))
        FileUtils.touch(File.join(workspace_content_dir, 'file2.vtt'))
        FileUtils.touch(File.join(workspace_content_dir, 'file3.json'))
        allow(mock_filter).to receive(:process)
      end

      it 'processes only txt and vtt files' do
        robot.perform_work

        expect(mock_filter).to have_received(:process).twice
        expect(mock_filter).to have_received(:process).with(Pathname.new(File.join(workspace_content_dir, 'file1.txt')))
        expect(mock_filter).to have_received(:process).with(Pathname.new(File.join(workspace_content_dir, 'file2.vtt')))
      end
    end

    context 'with no processable files' do
      before do
        FileUtils.touch(File.join(workspace_content_dir, 'file.json'))
        allow(mock_filter).to receive(:process)
      end

      it 'does not process any files' do
        robot.perform_work

        expect(mock_filter).not_to have_received(:process)
      end
    end
  end
end
