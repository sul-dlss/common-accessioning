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
      access: { download:, view: },
      structural: {
        contains: original_resources
      }
    )
  end
  let(:item_type) { Cocina::Models::ObjectType.media }
  let(:download) { 'world' }
  let(:view) { 'world' }

  # DruidTools needs to return the workspace_dir set up by "with workspace dir" context
  let(:druid_tools) do
    instance_double(DruidTools::Druid, id: bare_druid, content_dir: workspace_content_dir)
  end

  before { allow(DruidTools::Druid).to receive(:new).and_return(druid_tools) }

  context 'when there is a video and audio file' do
    let(:resource_type_video) { Cocina::Models::FileSetType.video }
    let(:resource_type_audio) { Cocina::Models::FileSetType.audio }

    let(:original_resources) do
      [
        {
          externalIdentifier: "#{bare_druid}_1",
          label: 'Video 1',
          type: resource_type_video,
          version: 1,
          structural: {
            contains: [
              {
                externalIdentifier: "#{bare_druid}_1",
                label: 'Video 1',
                type: Cocina::Models::ObjectType.file,
                version: 1,
                filename: 'file_1.mp4',
                hasMimeType: 'video/mp4',
                access: { download:, view: }
              }
            ]
          }
        },
        {
          externalIdentifier: "#{bare_druid}_2",
          label: 'Audio 1',
          type: resource_type_audio,
          version: 1,
          structural: {
            contains: [
              {
                externalIdentifier: "#{bare_druid}_2",
                label: 'Audio 1',
                type: Cocina::Models::ObjectType.file,
                version: 1,
                filename: 'file_1.m4a',
                hasMimeType: 'audio/m4a',
                access: { download:, view: }
              }
            ]
          }
        }
      ]
    end

    let(:resource1_files) { dro.structural.contains[0].structural.contains }
    let(:resource2_files) { dro.structural.contains[1].structural.contains }

    before do
      create_speech_to_text_file('file_1.mp4')
      create_speech_to_text_file('file_1_mp4.txt')
      create_speech_to_text_file('file_1_mp4.vtt')
      create_speech_to_text_file('file_1_mp4.json')
      create_speech_to_text_file('file_1.m4a')
      create_speech_to_text_file('file_1_m4a.txt')
      create_speech_to_text_file('file_1_m4a.vtt')
      create_speech_to_text_file('file_1_m4a.json')
      described_class.update(dro:)
    end

    it 'has expected number of resources' do
      expect(dro.structural.contains.length).to eq 2
    end

    it 'resources have expected number of files (mp4, txt, vtt, json)' do
      expect(resource1_files.length).to be 4
      expect(resource2_files.length).to be 4
    end

    it 'first resource still has video file set correctly' do
      file = resource1_files[0]
      expect(file.label).to eq 'Video 1'
      expect(file.filename).to eq 'file_1.mp4'
      expect(file.sdrGeneratedText).to be false
      expect(file.correctedForAccessibility).to be false
    end

    it 'second resource still has video file set correctly' do
      file = resource2_files[0]
      expect(file.label).to eq 'Audio 1'
      expect(file.filename).to eq 'file_1.m4a'
      expect(file.sdrGeneratedText).to be false
      expect(file.correctedForAccessibility).to be false
    end

    # rubocop:disable RSpec/ExampleLength
    it 'first resource has json file set correctly with shelve and publish as false' do
      file = resource1_files[1]
      expect(file.label).to eq 'file_1_mp4.json'
      expect(file.filename).to eq 'file_1_mp4.json'
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
      expect(file.label).to eq 'file_1_mp4.txt'
      expect(file.filename).to eq 'file_1_mp4.txt'
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
      expect(file.label).to eq 'file_1_mp4.vtt'
      expect(file.filename).to eq 'file_1_mp4.vtt'
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

    it 'second resource has json file set correctly with shelve and publish as false' do
      file = resource2_files[1]
      expect(file.label).to eq 'file_1_m4a.json'
      expect(file.filename).to eq 'file_1_m4a.json'
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

    it 'second resource has txt file set correctly with language pulled from json and shelve and publish as true' do
      file = resource2_files[2]
      expect(file.label).to eq 'file_1_m4a.txt'
      expect(file.filename).to eq 'file_1_m4a.txt'
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

    it 'second resource has vtt file set correctly with language pulled from json and shelve and publish as true' do
      file = resource2_files[3]
      expect(file.label).to eq 'file_1_m4a.vtt'
      expect(file.filename).to eq 'file_1_m4a.vtt'
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

    context 'when object access rights are restricted' do
      let(:download) { 'stanford' }
      let(:view) { 'stanford' }

      it 'sets the file level access rights to restricted' do
        expect(resource1_files[0].access.view).to eq('stanford') # original file
        expect(resource1_files[1].access.view).to eq('stanford') # new files below
        expect(resource1_files[2].access.view).to eq('stanford')
        expect(resource1_files[3].access.view).to eq('stanford')
        expect(resource1_files[1].access.download).to eq('stanford')
        expect(resource1_files[2].access.download).to eq('stanford')
        expect(resource1_files[3].access.download).to eq('stanford')
        expect(resource2_files[0].access.view).to eq('stanford') # original file
        expect(resource2_files[1].access.view).to eq('stanford') # new files below
        expect(resource2_files[2].access.view).to eq('stanford')
        expect(resource2_files[3].access.view).to eq('stanford')
        expect(resource2_files[1].access.download).to eq('stanford')
        expect(resource2_files[2].access.download).to eq('stanford')
        expect(resource2_files[3].access.download).to eq('stanford')
      end
    end

    context 'when object access rights are dark' do
      let(:download) { 'none' }
      let(:view) { 'dark' }

      it 'sets the file level access rights to dark' do
        expect(resource1_files[0].access.view).to eq('dark') # original file
        expect(resource1_files[1].access.view).to eq('dark') # new files below
        expect(resource1_files[2].access.view).to eq('dark')
        expect(resource1_files[3].access.view).to eq('dark')

        expect(resource1_files[0].access.download).to eq('none')
        expect(resource1_files[1].access.download).to eq('none')
        expect(resource1_files[2].access.download).to eq('none')
        expect(resource1_files[3].access.download).to eq('none')

        expect(resource1_files[0].administrative.shelve).to be false
        expect(resource1_files[1].administrative.shelve).to be false
        expect(resource1_files[2].administrative.shelve).to be false
        expect(resource1_files[3].administrative.shelve).to be false

        expect(resource1_files[0].administrative.sdrPreserve).to be true
        expect(resource1_files[1].administrative.sdrPreserve).to be true
        expect(resource1_files[2].administrative.sdrPreserve).to be true
        expect(resource1_files[3].administrative.sdrPreserve).to be true

        expect(resource1_files[0].administrative.publish).to be false
        expect(resource1_files[1].administrative.publish).to be false
        expect(resource1_files[2].administrative.publish).to be false
        expect(resource1_files[3].administrative.publish).to be false

        expect(resource2_files[0].access.view).to eq('dark') # original file
        expect(resource2_files[1].access.view).to eq('dark') # new files below
        expect(resource2_files[2].access.view).to eq('dark')
        expect(resource2_files[3].access.view).to eq('dark')

        expect(resource2_files[0].access.download).to eq('none')
        expect(resource2_files[1].access.download).to eq('none')
        expect(resource2_files[2].access.download).to eq('none')
        expect(resource2_files[3].access.download).to eq('none')
      end
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
