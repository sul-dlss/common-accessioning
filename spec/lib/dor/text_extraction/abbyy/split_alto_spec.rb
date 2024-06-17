# frozen_string_literal: true

require 'spec_helper'

describe Dor::TextExtraction::Abbyy::SplitAlto do
  subject(:results) { described_class.new(alto_path:) }

  let(:druid) { 'bb222cc3333' }
  let(:alto_path) { File.join(File.absolute_path('spec/fixtures/ocr'), "#{druid}_abbyy_alto.xml") }

  describe '.write_files' do
    let(:expected_files) { %w[bb222cc3333_00_0001.xml bb222cc3333_00_0002.xml bb222cc3333_00_0003.xml] }

    after { expected_files.each { |file| FileUtils.rm_f(File.join(File.dirname(alto_path), file)) } }

    it 'creates three XML files' do
      expect(expected_files.all? { |file| File.exist?(File.join(File.dirname(alto_path), file)) }).to be false
      expect(results.write_files).to be true
      expected_files.each do |file|
        actual_content = File.read(File.join(File.dirname(alto_path), file))
        expected_content = File.read(File.join(File.dirname(alto_path), "expected_#{file}"))
        expect(actual_content).to eq(expected_content)
      end
    end
  end

  describe '.page_filenames' do
    it 'finds the three filenames' do
      expect(results.send(:page_filenames)).to eq ['bb222cc3333_00_0001.tif', 'bb222cc3333_00_0002.tif', 'bb222cc3333_00_0003.tif']
    end

    context 'when alto sourceImageInformation is in different format' do
      let(:druid) { 'bb999cc1111' }

      it 'finds the single filename' do
        expect(results.send(:page_filenames)).to eq ['example.tiff']
      end
    end
  end

  describe '.output_path' do
    it 'expects output path to be same as alto_path' do
      expect(results.send(:output_path, 'bb222cc3333_00_0001.xml')).to include 'spec/fixtures/ocr/bb222cc3333_00_0001.xml'
    end
  end
end
