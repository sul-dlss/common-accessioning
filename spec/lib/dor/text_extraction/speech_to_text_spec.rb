# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::TextExtraction::SpeechToText do
  let(:stt) { described_class.new(cocina_object:, workflow_context:) }
  let(:object_type) { 'https://cocina.sul.stanford.edu/models/media' }
  let(:workflow_context) { {} }
  let(:structural) { instance_double(Cocina::Models::DROStructural, contains: [first_fileset, second_fileset, third_fileset]) }
  let(:first_fileset) { instance_double(Cocina::Models::FileSet, type: 'https://cocina.sul.stanford.edu/models/resources/audio', structural: first_fileset_structural) }
  let(:second_fileset) { instance_double(Cocina::Models::FileSet, type: 'https://cocina.sul.stanford.edu/models/resources/video', structural: second_fileset_structural) }
  let(:third_fileset) { instance_double(Cocina::Models::FileSet, type: 'https://cocina.sul.stanford.edu/models/resources/file', structural: third_fileset_structural) }
  let(:first_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [m4a_file, text_file]) }
  let(:second_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [mp4_file, mp4_file_not_shelved, mp4_file_not_preserved]) }
  let(:third_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [text_file2]) }
  let(:m4a_file) { build_file(true, true, 'file1.m4a') }
  let(:mp4_file) { build_file(true, true, 'file1.mp4') }
  let(:mp4_file_not_shelved) { build_file(true, false, 'file2.mp4') }
  let(:mp4_file_not_preserved) { build_file(false, true, 'file3.mp4') }
  let(:text_file) { build_file(true, true, 'file1.txt') }
  let(:text_file2) { build_file(true, true, 'file2.txt') }
  let(:druid) { 'druid:bc123df4567' }
  let(:bare_druid) { 'bc123df4567' }

  def build_file(sdr_preserve, shelve, filename)
    extension = File.extname(filename)
    mimetype = { '.m4a' => 'audio/mp4', '.mp4' => 'video/mp4', '.txt' => 'text/plain' }
    sdr_value = instance_double(Cocina::Models::FileAdministrative, sdrPreserve: sdr_preserve, shelve:)
    instance_double(Cocina::Models::File, administrative: sdr_value, hasMimeType: mimetype[extension], filename:)
  end

  describe '#possible?' do
    context 'when the object is not a DRO' do
      let(:cocina_object) { instance_double(Cocina::Models::Collection, externalIdentifier: druid, dro?: false, type: object_type) }

      it 'returns false' do
        expect(stt.possible?).to be false
      end
    end

    context 'when the object is a DRO' do
      let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: true, type: object_type, structural:) }

      context 'when the object type is one that does not require STT' do
        let(:object_type) { 'https://cocina.sul.stanford.edu/models/document' }

        it 'returns false' do
          expect(stt.possible?).to be false
        end
      end

      context 'when the object has no files that can be STTed' do
        let(:first_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [text_file]) }
        let(:second_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [text_file, text_file]) }

        it 'returns false' do
          expect(stt.possible?).to be false
        end
      end

      context 'when the object has files that can be STTed' do
        let(:first_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [m4a_file]) }

        it 'returns true' do
          expect(stt.possible?).to be true
        end
      end
    end
  end

  describe '#required?' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, dro?: true, type: object_type) }

    context 'when workflow context includes runSpeechToText as true' do
      let(:workflow_context) { { 'runSpeechToText' => true } }

      it 'returns true' do
        expect(stt.required?).to be true
      end
    end

    context 'when workflow context includes runSpeechToText as false' do
      let(:workflow_context) { { 'runSpeechToText' => false } }

      it 'returns false' do
        expect(stt.required?).to be false
      end
    end

    context 'when workflow context is empty' do
      let(:workflow_context) { {} }

      it 'returns false' do
        expect(stt.required?).to be false
      end
    end
  end

  describe '#filenames_to_stt' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, structural:, type: object_type) }

    it 'returns a list of filenames that should be STTed' do
      expect(stt.send(:filenames_to_stt)).to eq(['file1.m4a', 'file1.mp4'])
    end
  end

  describe '#stt_files' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, externalIdentifier: druid, structural:, type: object_type) }

    it 'returns a list of all filenames' do
      expect(stt.send(:stt_files)).to eq([m4a_file, mp4_file])
    end
  end

  describe '#job_id' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, version:, externalIdentifier: druid, dro?: true, type: object_type) }
    let(:version) { 3 }

    it 'returns the job_id for the STT job' do
      expect(stt.job_id).to eq("#{bare_druid}-v#{version}")
    end
  end
end
