# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::Abbyy::Ticket do
  include_context 'with abbyy dir'

  before do
    allow(Settings.sdr.abbyy).to receive_messages(
      local_ticket_path: abbyy_xml_ticket_path
    )
    FileUtils.mkdir_p(File.dirname(abbyy.file_path))
  end

  let(:druid) { 'druid:bb222cc3333' }
  let(:bare_druid) { druid.delete_prefix('druid:') }
  let(:abbyy) { described_class.new(filepaths:, druid:, ocr_languages:) }
  let(:ocr_languages) { nil }
  let(:ticket_xml) { abbyy.send(:xml) }
  let(:fixture_path) { File.join(File.absolute_path('spec/fixtures/ocr'), "#{bare_druid}_abbyy_ticket.xml") }

  context 'when the files are images' do
    let(:filepaths) { %w[filename1.jp2 filename2.jp2 filename3.jp2] }

    before { FileUtils.rm_f(abbyy.file_path) }

    it 'creates xml for files for images' do
      expect(ticket_xml).to be_equivalent_to File.read(fixture_path)
    end

    it 'writes the file to disk' do
      expect(File.exist?(abbyy.file_path)).to be false
      abbyy.write_xml
      expect(File.exist?(abbyy.file_path)).to be true
    end

    context 'when a language is provided' do
      let(:ocr_languages) { ['Spanish'] }
      let(:fixture_path) { File.join(File.absolute_path('spec/fixtures/ocr'), "#{bare_druid}_abbyy_ticket_spanish.xml") }

      it 'creates xml for files for images with a single language' do
        expect(ticket_xml).to be_equivalent_to File.read(fixture_path)
      end
    end

    context 'when multiple languages are provided' do
      let(:ocr_languages) { %w[Spanish Russian] }
      let(:fixture_path) { File.join(File.absolute_path('spec/fixtures/ocr'), "#{bare_druid}_abbyy_ticket_multilingual.xml") }

      it 'creates xml for files for images with multiple languages' do
        expect(ticket_xml).to be_equivalent_to File.read(fixture_path)
      end
    end
  end

  context 'when the files have hierarchy' do
    let(:druid) { 'druid:cc333dd4444' }
    let(:filepaths) { %w[subdir/filename1.jp2 filename2.jp2 filename3.jp2] }

    before { FileUtils.rm_f(abbyy.file_path) }

    it 'creates xml for files for images' do
      expect(ticket_xml).to be_equivalent_to File.read(fixture_path)
    end
  end

  context 'when the files are not images' do
    let(:filepaths) { %w[filename3.PDF filename4.pdf] }
    let(:druid) { 'druid:bc123df4567' }
    let(:ocr_languages) { %w[English Spanish German] }

    it 'creates xml for files for pdfs' do
      expect(ticket_xml).to be_equivalent_to File.read(fixture_path)
    end
  end
end
