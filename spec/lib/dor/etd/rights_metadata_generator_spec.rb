# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dor::Etd::RightsMetadataGenerator do
  describe '.generate' do
    subject(:generate) { described_class.generate(etd) }

    let(:etd) do
      Etd.new.tap do |e|
        e.properties.submit_date = '1472237669'
        e.properties.name = 'Midge Klump'
      end
    end

    it 'creates xml' do
      expect(generate).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
        <rightsMetadata objectId="">
          <copyright>
            <human>(c) Copyright 2016 by Midge Klump</human>
          </copyright>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <group>stanford</group>
            </machine>
          </access>
          <use>
            <machine type="creativeCommons">none</machine>
            <human type="creativeCommons"></human>
          </use>
        </rightsMetadata>
      XML
    end
  end
end
