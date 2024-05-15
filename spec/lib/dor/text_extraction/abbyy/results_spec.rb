# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::Abbyy::Results do
  subject(:results) { described_class.new(result_path:) }

  let(:druid) { 'bb222cc3333' }
  let(:result_path) { File.join(File.absolute_path('spec/fixtures/ocr'), "#{druid}.xml.result.xml") }

  it 'has a druid' do
    expect(results.druid).to eq druid
  end

  context 'when results successfully render' do
    it { is_expected.to be_success }

    it 'does not have failure messages' do
      expect(results.failure_messages.length).to be 0
    end

    it 'does have output documents' do
      output_docs = results.output_docs
      expect(output_docs.length).to be 3
      expect(output_docs).to eq ['/tmp/OUTPUT/bb222cc3333/bb222cc3333.pdf', '/tmp/OUTPUT/bb222cc3333/bb222cc3333.xml', '/tmp/OUTPUT/bb222cc3333/bb222cc3333.txt']
    end
  end

  context 'when results do not render' do
    let(:druid) { 'new_druid' }

    it { is_expected.not_to be_success }

    it 'has failure messages' do
      expect(results.failure_messages.length).to be 2
    end

    it 'does not have output documents' do
      output_docs = results.output_docs
      expect(output_docs.length).to be 1
      expect(output_docs).to eq ['/tmp/EXCEPTIONS/new_druid.xml']
    end
  end
end
