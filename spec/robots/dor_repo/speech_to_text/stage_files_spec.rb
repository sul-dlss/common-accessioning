# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::SpeechToText::StageFiles do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:bb222cc3333' }
  let(:version) { 1 }
  let(:robot) { described_class.new }
  let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: true, type: object_type, structural:) }
  let(:object_type) { Cocina::Models::ObjectType.media }
  let(:structural) { instance_double(Cocina::Models::DROStructural, contains: [fileset]) }
  let(:fileset) { instance_double(Cocina::Models::FileSet, type: Cocina::Models::FileSetType.audio, structural: fileset_structural) }
  let(:fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [m4a_file]) }
  let(:m4a_file) { build_file('file1.m4a') }
  let(:fake_workspace_path) { 'tmp/fake/workspace' }
  let(:workspace_client) do
    instance_double(Dor::Services::Client::Workspace, create: fake_workspace_path)
  end
  let(:object_client) do
    instance_double(Dor::Services::Client::Object, workspace: workspace_client)
  end
  let(:speech_to_text) do
    instance_double(Dor::TextExtraction::SpeechToText, output_location: "#{druid}-v#{version}/output")
  end
  let(:client) { instance_double(Aws::S3::Client) }
  let(:aws_m4a_txt_object) { instance_double(Aws::S3::Types::Object, key: 'file1.txt') }
  let(:aws_m4a_vtt_object) { instance_double(Aws::S3::Types::Object, key: 'file1.vtt') }
  let(:aws_m4a_json_object) { instance_double(Aws::S3::Types::Object, key: 'file1.json') }
  let(:aws_m4a_srt_object) { instance_double(Aws::S3::Types::Object, key: 'file1.srt') }
  let(:list_objects_output) { instance_double(Aws::S3::Types::ListObjectsOutput, contents: [aws_m4a_vtt_object, aws_m4a_txt_object, aws_m4a_json_object, aws_m4a_srt_object]) }
  let(:bucket) { Settings.aws.speech_to_text.base_s3_bucket }

  context 'when there are files to move' do
    before do
      FileUtils.mkdir_p("#{fake_workspace_path}/content") # simulute DorServices::Client::Workspace.create
      allow(Dor::TextExtraction::SpeechToText).to receive(:new).with(cocina_object:).and_return(speech_to_text)
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
      allow(object_client).to receive(:find).and_return(cocina_object)
      allow(client).to receive(:list_objects).and_return(list_objects_output)
      allow(client).to receive(:get_object).with(bucket:, key: 'file1.txt').and_yield(File.read('spec/fixtures/speech_to_text/file1.txt'))
      allow(client).to receive(:get_object).with(bucket:, key: 'file1.vtt').and_yield(File.read('spec/fixtures/speech_to_text/file1.vtt'))
      allow(client).to receive(:get_object).with(bucket:, key: 'file1.json').and_yield(File.read('spec/fixtures/speech_to_text/file1.json'))
      allow(Aws::S3::Client).to receive(:new).and_return(client)
    end

    after { FileUtils.rm_rf(fake_workspace_path) } # cleanup the fake workspace for the next test run

    # rubocop:disable RSpec/ExampleLength
    it 'copies only the vtt, json and txt files from s3 to local workspace' do
      # files are not in the local workspace
      %w[file.txt file.vtt file1.json file1.srt].each do |file|
        expect(File.exist?("#{fake_workspace_path}/content/#{file}")).to be false
      end

      expect(perform).to be true

      # correct files are now in the local workspace
      expect(File.exist?("#{fake_workspace_path}/content/file1.srt")).to be false # we didn't get the .srt!
      expect(File.exist?("#{fake_workspace_path}/content/file1.txt")).to be true
      expect(File.read("#{fake_workspace_path}/content/file1.txt")).to eq(File.read('spec/fixtures/speech_to_text/file1.txt'))
      expect(File.exist?("#{fake_workspace_path}/content/file1.vtt")).to be true
      expect(File.read("#{fake_workspace_path}/content/file1.vtt")).to eq(File.read('spec/fixtures/speech_to_text/file1.vtt'))
      expect(File.exist?("#{fake_workspace_path}/content/file1.json")).to be true
      expect(File.read("#{fake_workspace_path}/content/file1.json")).to eq(File.read('spec/fixtures/speech_to_text/file1.json'))
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
