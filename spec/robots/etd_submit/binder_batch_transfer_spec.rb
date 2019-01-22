# frozen_string_literal: true

require 'spec_helper'

describe Robots::DorRepo::EtdSubmit::BinderBatchTransfer do
  let(:hdrs) do
    hdr_line = 'dissertation id |druid|purl|catkey|searchworks URL|etd type|school|department|student name|title|pdf URL|CC license|embargo|release date|visibility'
    Robots::DorRepo::EtdSubmit::EtdInfo.parse_header(hdr_line)
  end

  describe Robots::DorRepo::EtdSubmit::EtdInfo do
    it '.parse_header extracts column headers from the etd report' do
      expect(hdrs.keys.size).to eq(15)
    end

    it '.parse_row returns an EtdInfo object as parsed from the row' do
      hdrs # make sure we parse the column headers before an actual row
      row = '0000002055|druid:wb667cd8631|http://purl.stanford.edu/wb667cd8631|9718124|http://searchworks.stanford.edu/view/9718124|dissertation|Humanities & Sciences|Chemistry|Brownell, Kristen Rose|Investigations of Ruthenium Transfer Hydrogenation Catalysts as Electrooxidation Catalysts for Alcohols|https://stacks.stanford.edu/file/druid:wb667cd8631/stanford_thesis-augmented.pdf|by-nc|2 years|2014-09-24|100%'
      etd = Robots::DorRepo::EtdSubmit::EtdInfo.parse_row(row)
      expect(etd.druid).to eq('druid:wb667cd8631')
      expect(etd.title).to eq('Investigations of Ruthenium Transfer Hydrogenation Catalysts as Electrooxidation Catalysts for Alcohols')
      expect(etd.student_name).to eq 'Brownell, Kristen Rose'
      expect(etd.catkey).to eq('9718124')
    end
  end
end
