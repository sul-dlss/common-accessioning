# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::Abbyy::Results do
  subject(:results) { described_class.new(result_path: results_file_path) }

  include_context 'with abbyy dir'
  include_context 'with workspace dir'

  let(:druid) { 'bb222cc3333' }
  let(:results_file_path) { "#{abbyy_result_xml_path}/#{druid}.xml.result.xml" }

  before do
    FileUtils.copy(
      "spec/fixtures/ocr/#{druid}.xml.result.xml",
      "#{abbyy_result_xml_path}/#{druid}.xml.result.xml"
    )

    allow(Settings.sdr.abbyy).to receive_messages(
      local_output_path: abbyy_output_path,
      local_result_path: abbyy_result_xml_path,
      local_exception_path: abbyy_exceptions_path
    )
  end

  it 'has a druid' do
    expect(results.druid).to eq druid
  end

  context 'when results successfully render' do
    it { is_expected.to be_success }

    it 'does not have failure messages' do
      expect(results.failure_messages.length).to be 0
    end

    it 'does have output documents' do
      expect(results.output_docs['pdfa']).to eq("#{abbyy_output_path}/bb222cc3333/bb222cc3333.pdf")
      expect(results.output_docs['alto']).to eq("#{abbyy_output_path}/bb222cc3333/bb222cc3333.xml")
      expect(results.output_docs['text']).to eq("#{abbyy_output_path}/bb222cc3333/bb222cc3333.txt")
    end

    it 'does have an alto doc' do
      expect(results.alto_doc).to eq "#{abbyy_output_path}/bb222cc3333/bb222cc3333.xml"
    end

    it 'can be found by druid' do
      found = described_class.find_latest(druid:)
      expect(found.druid).to eq druid
    end
  end

  context 'when there are results' do
    before do
      # create some files to move
      results.output_docs.each_value do |path|
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.touch(path)
      end
    end

    it 'can move files' do
      results.move_result_files(workspace_dir)
      expect(File.exist?(File.join(workspace_dir, 'bb222cc3333.txt'))).to be true
      expect(File.exist?(File.join(workspace_dir, 'bb222cc3333.pdf'))).to be true
      # we don't accession the full Abbyy OCR XML file
      expect(File.exist?(File.join(workspace_dir, 'bb222cc3333.xml'))).to be false
    end
  end

  context 'when there are results with split ocr' do
    before do
      results.output_docs.each_value do |path|
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.touch(path)
      end
      FileUtils.touch(File.join(abbyy_output_path, 'bb222cc3333', 'bb222cc3333_001.xml'))
      FileUtils.touch(File.join(abbyy_output_path, 'bb222cc3333', 'bb222cc3333_002.xml'))
    end

    it 'can move files' do
      results.move_result_files(workspace_dir)
      expect(File.exist?(File.join(workspace_dir, 'bb222cc3333.txt'))).to be true
      expect(File.exist?(File.join(workspace_dir, 'bb222cc3333.pdf'))).to be true
      # we don't accession the full Abbyy OCR XML file
      expect(File.exist?(File.join(workspace_dir, 'bb222cc3333.xml'))).to be false
      expect(File.exist?(File.join(workspace_dir, 'bb222cc3333_001.xml'))).to be true
      expect(File.exist?(File.join(workspace_dir, 'bb222cc3333_002.xml'))).to be true
    end
  end

  context 'when there are file specific XML files' do
    before do
      results.output_docs.each_value do |path|
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.touch(path)
      end
      FileUtils.touch(File.join(abbyy_output_path, 'bb222cc3333', 'file1.xml'))
      FileUtils.touch(File.join(abbyy_output_path, 'bb222cc3333', 'file2.xml'))
    end

    it 'can move files' do
      results.move_result_files(workspace_dir)
      expect(File.exist?(File.join(workspace_dir, 'bb222cc3333.txt'))).to be true
      expect(File.exist?(File.join(workspace_dir, 'bb222cc3333.pdf'))).to be true
      # we don't accession the full Abbyy OCR XML file
      expect(File.exist?(File.join(workspace_dir, 'bb222cc3333.xml'))).to be false
      expect(File.exist?(File.join(workspace_dir, 'file1.xml'))).to be true
      expect(File.exist?(File.join(workspace_dir, 'file2.xml'))).to be true
    end
  end

  context 'when results do not render' do
    let(:druid) { 'bc123df4567' }

    it { is_expected.not_to be_success }

    it 'has failure messages' do
      expect(results.failure_messages.length).to be 2
    end

    it 'does not have output documents' do
      output_docs = results.output_docs
      expect(output_docs.length).to be 1
      expect(output_docs).to eq({ 'noconversion' => 'E:\AbbyyShare\sdr-ocr-qa\EXCEPTIONS/bc123df4567.xml' })
    end

    it 'does not have an alto doc' do
      expect(results.alto_doc).to be_nil
    end
  end
end
