# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::SpeechToTextCocinaUpdater do
  # NOTE: this context makes workspace_dir, workspace_content_dir and workspace_metadata_dir available
  include_context 'with workspace dir'

  let(:druid) { 'druid:bb222cc3333' }
  let(:bare_druid) { 'bb222cc3333' }
  let(:dro) do
    build(:dro, id: druid).new(
      type: item_type,
      structural: {
        contains: original_resources
      }
    )
  end
  let(:item_type) { Cocina::Models::ObjectType.media }

  # DruidTools needs to return the workspace_dir set up by "with workspace dir" context
  let(:druid_tools) do
    instance_double(DruidTools::Druid, id: bare_druid, content_dir: workspace_content_dir)
  end

  before { allow(DruidTools::Druid).to receive(:new).and_return(druid_tools) }

  context 'when there is a video file' do
    let(:resource_type) { Cocina::Models::FileSetType.video }

    let(:original_resources) do
      [
        {
          externalIdentifier: "#{bare_druid}_1",
          label: 'Fileset 1',
          type: resource_type,
          version: 1,
          structural: {
            contains: [
              {
                externalIdentifier: "#{bare_druid}_1",
                label: 'Video 1',
                type: Cocina::Models::ObjectType.file,
                version: 1,
                filename: 'file1.mp4',
                hasMimeType: 'video/mp4'
              }
            ]
          }
        }
      ]
    end

    let(:resource1_files) { dro.structural.contains[0].structural.contains }

    before do
      create_speech_to_text_file('file1.mp4')
      create_speech_to_text_file('file1.txt')
      create_speech_to_text_file('file1.vtt')
      create_speech_to_text_file('file1.json')
      described_class.update(dro:)
    end

    it 'has expected number of resources' do
      expect(dro.structural.contains.length).to eq 1
    end

    it 'first resource has expected number of files (mp4, txt, vtt, json)' do
      expect(resource1_files.length).to be 4
    end

    it 'first resource still has video file set correctly' do
      file = resource1_files[0]
      expect(file.label).to eq 'Video 1'
      expect(file.filename).to eq 'file1.mp4'
      expect(file.sdrGeneratedText).to be false
      expect(file.correctedForAccessibility).to be false
    end

    # rubocop:disable RSpec/ExampleLength
    it 'first resource has json file set correctly with shelve and publish as false' do
      file = resource1_files[1]
      expect(file.label).to eq 'file1.json'
      expect(file.filename).to eq 'file1.json'
      expect(file.use).to be_nil
      expect(file.sdrGeneratedText).to be true
      expect(file.correctedForAccessibility).to be false
      expect(file.access.view).to be 'world'
      expect(file.access.download).to be 'world'
      expect(file.administrative.publish).to be false
      expect(file.administrative.sdrPreserve).to be true
      expect(file.administrative.shelve).to be false
      expect(file.hasMimeType).to eq 'application/json'
      expect(file.hasMessageDigests[0].type).to eq 'md5'
      expect(file.hasMessageDigests[0].digest).to eq '8b43304039be0e1cc7be600cf77818bb'
      expect(file.hasMessageDigests[1].type).to eq 'sha1'
      expect(file.hasMessageDigests[1].digest).to eq '0cc8fa02921cac04613ff6c4dae56f4f8ae183af'
      expect(file.languageTag).to eq 'es'
    end

    it 'first resource has txt file set correctly with language pulled from json and shelve and publish as true' do
      file = resource1_files[2]
      expect(file.label).to eq 'file1.txt'
      expect(file.filename).to eq 'file1.txt'
      expect(file.use).to eq 'transcription'
      expect(file.sdrGeneratedText).to be true
      expect(file.correctedForAccessibility).to be false
      expect(file.access.view).to be 'world'
      expect(file.access.download).to be 'world'
      expect(file.administrative.publish).to be true
      expect(file.administrative.sdrPreserve).to be true
      expect(file.administrative.shelve).to be true
      expect(file.hasMimeType).to eq 'text/plain'
      expect(file.hasMessageDigests[0].type).to eq 'md5'
      expect(file.hasMessageDigests[0].digest).to eq '001e221aa51284559ca4b91ac8f3a715'
      expect(file.hasMessageDigests[1].type).to eq 'sha1'
      expect(file.hasMessageDigests[1].digest).to eq 'e8fa65dbcdf116c762fdaf9e78e38a28ad778ae0'
      expect(file.languageTag).to eq 'es'
    end

    it 'first resource has vtt file set correctly with language pulled from json and shelve and publish as true' do
      file = resource1_files[3]
      expect(file.label).to eq 'file1.vtt'
      expect(file.filename).to eq 'file1.vtt'
      expect(file.use).to eq 'caption'
      expect(file.sdrGeneratedText).to be true
      expect(file.correctedForAccessibility).to be false
      expect(file.access.view).to be 'world'
      expect(file.access.download).to be 'world'
      expect(file.administrative.publish).to be true
      expect(file.administrative.sdrPreserve).to be true
      expect(file.administrative.shelve).to be true
      expect(file.hasMimeType).to eq 'text/vtt'
      expect(file.languageTag).to eq 'es'
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
