# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::Abbyy do
  describe described_class::Ticket do
    let(:druid) { 'druid:bb222cc3333' }
    let(:abbyy) { described_class.new(filepaths:, druid:) }
    let(:ticket_xml) { abbyy.send(:xml) }
    let(:fixture_path) { File.join(File.absolute_path('spec/fixtures/ocr'), "#{druid}_abbyy_ticket.xml") }

    context 'when the files are images' do
      let(:file_path) { abbyy.send(:file_path) }
      let(:filepaths) { %w[/with/path/filename1.jp2 filename2.jp2 filename3.jp2] }

      before { FileUtils.rm_f(file_path) }

      it 'creates xml for files for images' do
        expect(ticket_xml).to be_equivalent_to File.read(fixture_path)
      end

      it 'writes the file to disk' do
        expect(File.exist?(file_path)).to be false
        abbyy.write_xml
        expect(File.exist?(file_path)).to be true
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

  describe described_class::Results do
    let(:druid) { 'druid:bb222cc3333' }
    let(:result_path) { File.join(File.absolute_path('spec/fixtures/ocr'), "#{druid}.xml.result.xml") }
    let(:abbyy) { described_class.new(result_path:) }

    context 'when results successfully render' do
      it 'successfully returns results' do
        expect(abbyy.send(:success?)).to be true
      end

      it 'does not have failure messages' do
        expect(abbyy.send(:failure_messages).length).to be 0
      end

      it 'does have output documents' do
        output_docs = abbyy.send(:output_docs)
        expect(output_docs.length).to be 3
        expect(output_docs).to eq ['/tmp/OUTPUT/bb222cc3333/bb222cc3333.pdf', '/tmp/OUTPUT/bb222cc3333/bb222cc3333.xml', '/tmp/OUTPUT/bb222cc3333/bb222cc3333.txt']
      end
    end

    context 'when results do not render' do
      let(:druid) { 'druid:new_druid' }

      it 'unsuccessfully returns results' do
        expect(abbyy.send(:success?)).to be false
      end

      it 'has failure messages' do
        expect(abbyy.send(:failure_messages).length).to be 2
      end

      it 'does not have output documents' do
        output_docs = abbyy.send(:output_docs)
        expect(output_docs.length).to be 1
        expect(output_docs).to eq ['/tmp/EXCEPTIONS/new_druid.xml']
      end
    end
  end
end
