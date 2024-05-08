# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::Abbyy do
  let(:druid) { 'druid:bb222cc3333' }
  let(:abbyy) { described_class.new(filepaths:, druid:) }
  let(:ticket_xml) { abbyy.send(:xml_ticket) }
  let(:fixture_path) { File.join(File.absolute_path('spec/fixtures/ocr'), "#{druid}_abbyy_ticket.xml") }

  context 'when the files are images' do
    let(:abbyy_ticket_filepath) { abbyy.send(:abbyy_ticket_filepath) }
    let(:filepaths) { %w[/with/path/filename1.jp2 filename2.jp2 filename3.jp2] }

    before { FileUtils.rm_f(abbyy_ticket_filepath) }

    it 'creates xml for files for images' do
      expect(ticket_xml).to be_equivalent_to File.read(fixture_path)
    end

    it 'writes the file to disk' do
      expect(File.exist?(abbyy_ticket_filepath)).to be false
      abbyy.write_xml_ticket
      expect(File.exist?(abbyy_ticket_filepath)).to be true
    end
  end

  context 'when the files are not images' do
    let(:filepaths) { %w[filename3.PDF filename4.pdf] }
    let(:druid) { 'druid:new_druid' }

    it 'creates xml for files for pdfs' do
      expect(ticket_xml).to be_equivalent_to File.read(fixture_path)
    end
  end
end
