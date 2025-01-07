# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::SpeechToText::UpdateCocina do
  include_context 'with workspace dir'

  let(:robot) { described_class.new }
  let(:bare_druid) { 'bb222cc3333' }
  let(:druid) { "druid:#{bare_druid}" }

  # DruidTools needs to return the workspace_dir set up by "with workspace dir" context
  let(:druid_tools) do
    instance_double(DruidTools::Druid, id: bare_druid, content_dir: workspace_content_dir)
  end

  let(:dsa_object_client) do
    instance_double(Dor::Services::Client::Object, find: cocina_model, update: true)
  end

  # set up a Cocina object with one audio file in it
  let(:cocina_model) { build(:dro, id: druid).new(structural:, type: object_type) }
  let(:object_type) { Cocina::Models::ObjectType.media }
  let(:structural) do
    {
      contains: [
        {
          type: Cocina::Models::FileSetType.file,
          externalIdentifier: "#{bare_druid}_1",
          label: 'Audio 1',
          version: 1,
          structural: {
            contains: [
              {
                type: Cocina::Models::ObjectType.file,
                externalIdentifier: "#{druid}_1",
                label: 'file1.m4a',
                filename: 'file1.m4a',
                size: 123,
                version: 1,
                hasMimeType: 'audio/mp4'
              }
            ]
          }
        }
      ]
    }
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(dsa_object_client)

    allow(DruidTools::Druid).to receive(:new).and_return(druid_tools)
  end

  context 'with a vtt file' do
    # setup a fake caption vtt and json file in the workspace directory which matches the name of the audio file in the Cocina
    before do
      create_speech_to_text_file('file1.vtt')
      create_speech_to_text_file('file1.json')
    end

    it 'runs the update cocina robot and sets the caption role' do
      new_cocina = test_perform(robot, druid)
      expect(new_cocina.structural.contains.size).to eq 1
      new_json_file = new_cocina.structural.contains[0].structural.contains[1]
      new_vtt_file = new_cocina.structural.contains[0].structural.contains[2]
      expect(new_json_file.filename).to eq 'file1.json'
      expect(new_json_file.use).to be_nil
      expect(new_vtt_file.filename).to eq 'file1.vtt'
      expect(new_vtt_file.use).to eq 'caption'
    end
  end

  context 'with vtt files and input files with the same filename but different extensions' do
    let(:structural) do
      {
        contains: [
          {
            type: Cocina::Models::FileSetType.file,
            externalIdentifier: "#{bare_druid}_1",
            label: 'Audio 1',
            version: 1,
            structural: {
              contains: [
                {
                  type: Cocina::Models::ObjectType.file,
                  externalIdentifier: "#{druid}_1",
                  label: 'file1.m4a',
                  filename: 'file1.m4a',
                  size: 123,
                  version: 1,
                  hasMimeType: 'audio/mp4'
                }
              ]
            }
          },
          {
            type: Cocina::Models::FileSetType.file,
            externalIdentifier: "#{bare_druid}_1",
            label: 'Video 1',
            version: 1,
            structural: {
              contains: [
                {
                  type: Cocina::Models::ObjectType.file,
                  externalIdentifier: "#{druid}_1",
                  label: 'file1.mp4',
                  filename: 'file1.mp4',
                  size: 123,
                  version: 1,
                  hasMimeType: 'video/mp4'
                }
              ]
            }
          }
        ]
      }
    end

    # setup fake caption vtt and json files in the workspace directory which matches the names of the audio and video files in the Cocina
    before do
      create_speech_to_text_file('file1_m4a.vtt')
      create_speech_to_text_file('file1_m4a.json')
      create_speech_to_text_file('file1_mp4.vtt')
      create_speech_to_text_file('file1_mp4.json')
    end

    # rubocop:disable RSpec/ExampleLength
    it 'runs the update cocina robot and correctly adds the renamed output files to the correct resource' do
      new_cocina = test_perform(robot, druid)
      new_audio_json_file = new_cocina.structural.contains[0].structural.contains[1]
      new_audio_vtt_file = new_cocina.structural.contains[0].structural.contains[2]
      new_video_json_file = new_cocina.structural.contains[1].structural.contains[1]
      new_video_vtt_file = new_cocina.structural.contains[1].structural.contains[2]
      expect(new_cocina.structural.contains.size).to eq 2
      expect(new_cocina.structural.contains[0].structural.contains[0].filename).to eq 'file1.m4a'
      expect(new_audio_json_file.filename).to eq 'file1_m4a.json'
      expect(new_audio_json_file.use).to be_nil
      expect(new_audio_vtt_file.filename).to eq 'file1_m4a.vtt'
      expect(new_audio_vtt_file.use).to eq 'caption'
      expect(new_cocina.structural.contains[1].structural.contains[0].filename).to eq 'file1.mp4'
      expect(new_video_json_file.filename).to eq 'file1_mp4.json'
      expect(new_video_json_file.use).to be_nil
      expect(new_video_vtt_file.filename).to eq 'file1_mp4.vtt'
      expect(new_video_vtt_file.use).to eq 'caption'
    end
    # rubocop:enable RSpec/ExampleLength
  end

  context 'with a txt file' do
    # setup a fake caption txt and json file in the workspace directory which matches the name of the audio file in the Cocina
    before do
      create_speech_to_text_file('file1.txt')
      create_speech_to_text_file('file1.json')
    end

    it 'runs the update cocina robot and sets the transcription role' do
      new_cocina = test_perform(robot, druid)
      new_json_file = new_cocina.structural.contains[0].structural.contains[1]
      new_txt_file = new_cocina.structural.contains[0].structural.contains[2]
      expect(new_json_file.filename).to eq 'file1.json'
      expect(new_json_file.use).to be_nil
      expect(new_txt_file.filename).to eq 'file1.txt'
      expect(new_txt_file.use).to eq 'transcription'
    end
  end

  context 'with a missing json file' do
    # setup a fake caption txt file with no json file in the workspace directory which matches the name of the audio file in the Cocina
    before { create_speech_to_text_file('file1.txt') }

    it 'raises an error that a json file was not found' do
      expect { test_perform(robot, druid) }.to raise_error(/missing expected json file/)
    end
  end
end
