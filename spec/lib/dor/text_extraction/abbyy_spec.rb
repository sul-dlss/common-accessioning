# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::Abbyy do
  let(:druid) { 'druid:bb222cc3333' }
  let(:abbyy) { described_class.new(filepaths:, druid:) }
  let(:xml_contents) { parse_xml(abbyy.abbyy_ticket_filepath) }
  let(:fixture_path) { File.join(File.absolute_path('spec/fixtures/ocr'), "#{druid}_abbyy_ticket.xml") }

  def parse_xml(filepath)
    Nokogiri::XML(File.read(filepath)).to_xml.gsub(/\s+/, ' ').strip
  end

  before do
    abbyy.xml_ticket
  end

  context 'when the files are images' do
    let(:filepaths) { %w[/with/path/filename1.jp2 filename2.jp2 filename3.jp2] }

    it 'creates xml for files for images' do
      expect(xml_contents).to eq parse_xml(fixture_path)
    end
  end

  context 'when the files are not images' do
    let(:filepaths) { %w[filename3.PDF filename4.pdf] }
    let(:druid) { 'druid:new_druid' }

    it 'creates xml for files for pdfs' do
      expect(xml_contents).to eq parse_xml(fixture_path)
    end
  end
end
