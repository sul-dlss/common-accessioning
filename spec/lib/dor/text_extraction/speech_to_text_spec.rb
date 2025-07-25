# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::TextExtraction::SpeechToText do
  let(:stt) { described_class.new(cocina_object:, workflow_context:) }
  let(:druid) { 'druid:bc123df4567' }
  let(:bare_druid) { 'bc123df4567' }
  let(:cocina_object) { instance_double(Cocina::Models::DRO, version:, structural:, externalIdentifier: druid, dro?: is_dro, type: object_type) }
  let(:is_dro) { true }
  let(:version) { 1 }
  let(:object_type) { Cocina::Models::ObjectType.media }
  let(:workflow_context) { {} }
  let(:structural) { instance_double(Cocina::Models::DROStructural, contains: [first_fileset, second_fileset, third_fileset]) }
  let(:first_fileset) { instance_double(Cocina::Models::FileSet, type: Cocina::Models::FileSetType.audio, structural: first_fileset_structural) }
  let(:second_fileset) { instance_double(Cocina::Models::FileSet, type: Cocina::Models::FileSetType.video, structural: second_fileset_structural) }
  let(:third_fileset) { instance_double(Cocina::Models::FileSet, type: Cocina::Models::FileSetType.file, structural: third_fileset_structural) }
  let(:first_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [m4a_file, text_file]) }
  let(:second_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [mp4_file, mp4_file_not_shelved, mp4_file_not_preserved]) }
  let(:third_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [text_file2]) }
  let(:m4a_file) { build_file('file1.m4a') }
  let(:mp4_file) { build_file('file1.mp4', language_tag: 'es') }
  let(:mp4_file_not_shelved) { build_file('file2.mp4', shelve: false) }
  let(:mp4_file_not_preserved) { build_file('file3.mp4', preserve: false) }
  let(:text_file) { build_file('file1.txt') }
  let(:text_file2) { build_file('file2.txt') }
  let(:tech_md_response) { File.read("spec/fixtures/technical_metadata/#{bare_druid}.json") }

  before do
    stub_request(:get, "https://dor-techmd-test.stanford.test/v1/technical-metadata/druid/#{druid}")
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'Bearer rake-generate-token-me',
          'Content-Type' => 'application/json'
        }
      )
      .to_return(status: 200, body: tech_md_response, headers: {})
  end

  describe '#possible?' do
    context 'when the object is not a DRO' do
      let(:is_dro) { false }

      it 'returns false' do
        expect(stt.possible?).to be false
      end
    end

    context 'when the object is a DRO' do
      context 'when the object type is one that does not require STT' do
        let(:object_type) { Cocina::Models::ObjectType.document }

        it 'returns false' do
          expect(stt.possible?).to be false
        end
      end

      context 'when the object has no files that can be STTed' do
        let(:first_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [text_file]) }
        let(:second_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [text_file, text_file2]) }

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

  describe '#language_tag' do
    context 'when the file cannot be found' do
      let(:filename) { 'bogus.mp4' }
      let(:s3_filename) { 'bogus_mp4.mp4' }

      it 'returns nil' do
        expect(stt.filenames_to_stt).not_to include(filename)
        expect(stt.language_tag(s3_filename)).to be_nil
      end
    end

    context 'when the file is found and there is no language tag in cocina' do
      let(:filename) { 'file1.m4a' }
      let(:s3_filename) { 'file1_m4a.m4a' }

      it 'returns nil' do
        expect(stt.filenames_to_stt).to include(filename)
        expect(stt.language_tag(s3_filename)).to be_nil
      end
    end

    context 'when the file is found and there is a language tag in cocina' do
      let(:filename) { 'file1.mp4' }
      let(:s3_filename) { 'file1_mp4.mp4' }

      it 'returns the language tag' do
        expect(stt.filenames_to_stt).to include(filename)
        expect(stt.language_tag(s3_filename)).to eq 'es'
      end
    end

    context 'when the file is found, the s3 filename is the same as the cocina filename and there is a language tag in cocina' do
      let(:filename) { 'file1.mp4' }
      let(:s3_filename) { 'file1.mp4' }

      it 'returns the language tag' do
        expect(stt.filenames_to_stt).to include(filename)
        expect(stt.language_tag(s3_filename)).to eq 'es'
      end
    end
  end

  describe '#cleanup' do
    let(:client) { instance_double(Aws::S3::Client, list_objects:) }
    let(:list_objects) { instance_double(Aws::S3::Types::ListObjectsOutput, contents: [m4a_object, mp4_object]) }
    let(:m4a_object) { instance_double(Aws::S3::Types::Object, key: "#{bare_druid}-v#{version}/file1.m4a") }
    let(:mp4_object) { instance_double(Aws::S3::Types::Object, key: "#{bare_druid}-v#{version}/file1.mp4") }
    let(:version) { 2 }

    before do
      allow(Aws::S3::Client).to receive(:new).and_return(client)
      allow(client).to receive(:delete_object).and_return(instance_double(Aws::S3::Types::Object))
    end

    it 'removes all files from s3' do
      expect(stt.cleanup).to be true
      expect(client).to have_received(:delete_object).with(bucket: Settings.aws.speech_to_text.base_s3_bucket, key: "#{bare_druid}-v#{version}/file1.m4a").once
      expect(client).to have_received(:delete_object).with(bucket: Settings.aws.speech_to_text.base_s3_bucket, key: "#{bare_druid}-v#{version}/file1.mp4").once
    end
  end

  describe '#filenames_to_stt' do
    it 'returns a list of filenames that should be STTed, ignoring those not in preservation or shelved' do
      expect(stt.send(:filenames_to_stt)).to eq(['file1.m4a', 'file1.mp4'])
    end

    context 'when a speech to text file exists but is marked correctedForAccessibility' do
      let(:vtt_file) { build_file('file1.vtt', corrected: true) }
      let(:second_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [mp4_file, vtt_file]) }

      it 'ignores the mp4 file which has a corresponding vtt file that has been corrected for accessibility' do
        expect(stt.send(:filenames_to_stt)).to eq(['file1.m4a'])
      end
    end

    context 'when a speech to text file exists but has no audio track' do
      let(:tech_md_response) { File.read("spec/fixtures/technical_metadata/#{bare_druid}_no_audio_track.json") }

      it 'ignores the m4a file which has no audio track' do
        expect(stt.send(:filenames_to_stt)).to eq(['file1.mp4'])
      end
    end

    context 'when a speech to text file exists which has a mostly quiet audio track' do
      let(:tech_md_response) { File.read("spec/fixtures/technical_metadata/#{bare_druid}_quiet_audio_track.json") }

      it 'ignores the m4a file which has a mostly quiet audio track' do
        expect(stt.send(:filenames_to_stt)).to eq(['file1.mp4'])
      end
    end

    context 'when an OCR file exists and is NOT marked correctedForAccessibility and is also NOT sdrGenerated' do
      let(:vtt_file) { build_file('file1.vtt', corrected: false, sdr_generated: false) }
      let(:second_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [mp4_file, vtt_file]) }

      it 'ignores the mp4 file which has a corresponding vtt file which has not been corrected for accessibility but was also not sdr generated' do
        expect(stt.send(:filenames_to_stt)).to eq(['file1.m4a'])
      end
    end

    context 'when an OCR file exists and is NOT marked correctedForAccessibility but is sdrGenerated' do
      let(:vtt_file) { build_file('file1.vtt', corrected: false, sdr_generated: true) }
      let(:second_fileset_structural) { instance_double(Cocina::Models::FileSetStructural, contains: [mp4_file, vtt_file]) }

      it 'returns the both the m4a and mp4 file which has a corresponding vtt file which has not been corrected for accessibility but is sdr generated' do
        expect(stt.send(:filenames_to_stt)).to eq(['file1.m4a', 'file1.mp4'])
      end
    end
  end

  describe '#stt_files' do
    it 'returns a list of all filenames' do
      expect(stt.send(:stt_files)).to eq([m4a_file, mp4_file])
    end
  end

  describe '#acceptable_file?' do
    context 'when file is preserved, shelved, and has an allowed mimetype' do
      let(:file) { build_file('file1.mp4') }

      it 'returns true' do
        expect(stt.send(:acceptable_file?, file)).to be true
      end
    end

    context 'when file is not preserved' do
      let(:file) { build_file('file1.mp4', preserve: false) }

      it 'returns false' do
        expect(stt.send(:acceptable_file?, file)).to be false
      end
    end

    context 'when file is not shelved' do
      let(:file) { build_file('file1.mp4', shelve: false) }

      it 'returns false' do
        expect(stt.send(:acceptable_file?, file)).to be false
      end
    end

    context 'when file has a disallowed mimetype for speech to text' do
      let(:file) { build_file('file1.txt') }

      it 'returns false' do
        expect(stt.send(:acceptable_file?, file)).to be false
      end
    end
  end

  describe '#s3_location' do
    let(:version) { 3 }

    it 'returns the new s3 filename key for a given filename' do
      expect(stt.s3_location('text.xml')).to eq("#{bare_druid}-v#{version}/text_xml.xml")
    end
  end

  describe '#s3_filename' do
    it 'returns the new s3 base filename for a given cocina filename' do
      expect(stt.s3_filename('text.xml')).to eq('text_xml.xml')
    end
  end

  describe '#cocina_filename' do
    it 'returns the original cocina filename for a given s3 filename' do
      expect(stt.cocina_filename('text_xml.xml')).to eq('text.xml')
    end
  end

  describe '#job_id' do
    let(:version) { 3 }

    it 'returns the job_id for the STT job' do
      expect(stt.job_id).to eq("#{bare_druid}-v#{version}")
    end
  end

  describe '#output_location' do
    let(:version) { 3 }

    it 'returns the output_location for the STT job' do
      expect(stt.output_location).to eq("#{bare_druid}-v#{version}/output")
    end
  end

  describe '#tech_metadata' do
    context 'when the technical metadata service returns a successful response' do
      it 'returns the parsed JSON response' do
        expect(stt.send(:tech_metadata)).to eq(JSON.parse(tech_md_response))
      end
    end

    context 'when the technical metadata service returns an unsuccessful response' do
      before do
        stub_request(:get, "https://dor-techmd-test.stanford.test/v1/technical-metadata/druid/#{druid}")
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization' => 'Bearer rake-generate-token-me',
              'Content-Type' => 'application/json'
            }
          )
          .to_return(status: 500, body: 'Internal Server Error', headers: {})
      end

      it 'raises an error with the response status and body' do
        expect { stt.send(:tech_metadata) }.to raise_error(RuntimeError, "Technical-metadata-service returned 500 when requesting techmd for #{bare_druid}: Internal Server Error")
      end
    end
  end

  describe '#has_useful_audio_track?' do
    let(:filename) { 'file1.m4a' }

    context 'when the file has an audio track with normal volume levels' do
      let(:tech_md_response) do
        {
          'filename' => filename,
          'av_metadata' => {
            'audio_count' => 1
          },
          'dro_file_parts' => [
            {
              'part_type' => 'audio',
              'audio_metadata' => {
                'mean_volume' => -35,
                'max_volume' => -25
              }
            }
          ]
        }.to_json
      end

      it 'returns true' do
        allow(stt).to receive(:tech_metadata).and_return([JSON.parse(tech_md_response)])
        expect(stt.send(:has_useful_audio_track?, filename)).to be true
      end
    end

    context 'when the file does not have an audio track' do
      let(:tech_md_response) do
        {
          'filename' => filename,
          'av_metadata' => {
            'audio_count' => 0
          }
        }.to_json
      end

      it 'returns false' do
        allow(stt).to receive(:tech_metadata).and_return([JSON.parse(tech_md_response)])
        expect(stt.send(:has_useful_audio_track?, filename)).to be false
      end
    end

    context 'when the file does not have an av_metadata block' do
      let(:tech_md_response) do
        {
          'filename' => filename
        }.to_json
      end

      it 'returns false' do
        allow(stt).to receive(:tech_metadata).and_return([JSON.parse(tech_md_response)])
        expect(stt.send(:has_useful_audio_track?, filename)).to be false
      end
    end

    context 'when the file is not present in the technical metadata' do
      let(:tech_md_response) { [].to_json }

      it 'returns false' do
        allow(stt).to receive(:tech_metadata).and_return(JSON.parse(tech_md_response))
        expect(stt.send(:has_useful_audio_track?, filename)).to be false
      end
    end

    context 'when the file has an audio track with very low audio levels' do
      let(:tech_md_response) do
        {
          'filename' => filename,
          'av_metadata' => {
            'audio_count' => 1
          },
          'dro_file_parts' => [
            {
              'part_type' => 'audio',
              'audio_metadata' => {
                'mean_volume' => -45,
                'max_volume' => -35
              }
            }
          ]
        }.to_json
      end

      it 'returns false' do
        allow(stt).to receive(:tech_metadata).and_return([JSON.parse(tech_md_response)])
        expect(stt.send(:has_useful_audio_track?, filename)).to be false
      end
    end

    context 'when the file has an audio track but has no audio metadata' do
      let(:tech_md_response) do
        {
          'filename' => filename,
          'av_metadata' => {
            'audio_count' => 1
          },
          'dro_file_parts' => [
            {
              'part_type' => 'video'
            }
          ]
        }.to_json
      end

      it 'raises an exception' do
        allow(stt).to receive(:tech_metadata).and_return([JSON.parse(tech_md_response)])
        expect { stt.send(:has_useful_audio_track?, filename) }.to raise_error(RuntimeError, "No audio metadata found for #{filename}")
      end
    end

    context 'when the file has an audio track but is missing the mean/max volume from audio metadata' do
      let(:tech_md_response) do
        {
          'filename' => filename,
          'av_metadata' => {
            'audio_count' => 1
          },
          'dro_file_parts' => [
            {
              'part_type' => 'video'
            },
            {
              'part_type' => 'audio',
              'audio_metadata' => {
                'channels' => '2'
              }
            }
          ]
        }.to_json
      end

      it 'raises an exception' do
        allow(stt).to receive(:tech_metadata).and_return([JSON.parse(tech_md_response)])
        expect { stt.send(:has_useful_audio_track?, filename) }.to raise_error(RuntimeError, "Audio metadata missing max_volume and mean_volume for #{filename}")
      end
    end

    context 'when the file has an audio track but has no dro_file_parts' do
      let(:tech_md_response) do
        {
          'filename' => filename,
          'av_metadata' => {
            'audio_count' => 1
          }
        }.to_json
      end

      it 'raises an exception' do
        allow(stt).to receive(:tech_metadata).and_return([JSON.parse(tech_md_response)])
        expect { stt.send(:has_useful_audio_track?, filename) }.to raise_error(RuntimeError, "No audio metadata found for #{filename}")
      end
    end
  end
end
