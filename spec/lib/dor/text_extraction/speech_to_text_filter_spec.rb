# frozen_string_literal: true

RSpec.describe Dor::TextExtraction::SpeechToTextFilter do
  let(:input_txt_filename) { 'caption_file.txt' }
  let(:input_vtt_filename) { 'caption_file.vtt' }
  let(:cleaned_txt_filename) { 'caption_file_cleaned.txt' }
  let(:cleaned_vtt_filename) { 'caption_file_cleaned.vtt' }
  let(:input_path) { 'spec/test_input' }
  let(:tmp_folder) { 'tmp' }
  let(:txt_full_path) { File.join(tmp_folder, input_txt_filename) }
  let(:vtt_full_path) { File.join(tmp_folder, input_vtt_filename) }

  let(:filter) { described_class.new }

  describe '#process' do
    # copy text and vtt files to tmp directory so we can process them without altering the originals
    before do
      FileUtils.cp(File.join(input_path, input_txt_filename), txt_full_path)
      FileUtils.cp(File.join(input_path, input_vtt_filename), vtt_full_path)
    end

    after do
      FileUtils.rm_f(txt_full_path)
      FileUtils.rm_f(vtt_full_path)
    end

    it 'removes filtered phrases from the text file' do
      expect(filter.process(txt_full_path)).to be true
      expect(File.read(txt_full_path)).to eq File.read(File.join(input_path, cleaned_txt_filename))
    end

    it 'removes filtered phrases from the vtt file' do
      expect(filter.process(vtt_full_path)).to be true
      expect(File.read(vtt_full_path)).to eq File.read(File.join(input_path, cleaned_vtt_filename))
    end
  end
end
