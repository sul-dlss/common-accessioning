# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::Abbyy::SplitAlto do
  subject(:results) { described_class.new(alto_path:) }

  let(:druid) { 'bb222cc3333' }
  let(:alto_path) { File.join(File.absolute_path('spec/fixtures/ocr'), "#{druid}_abbyy_alto.xml") }

  it 'splits into three alto files' do
    expect(results.send(:split_to_files).keys).to eq ['bb222cc3333_00_0001.xml', 'bb222cc3333_00_0002.xml', 'bb222cc3333_00_0003.xml']
  end

  it 'expects output path to be same as alto_path' do
    expect(results.send(:output_path, 'bb222cc3333_00_0001.xml')).to include 'spec/fixtures/ocr/bb222cc3333_00_0001.xml'
  end
end
