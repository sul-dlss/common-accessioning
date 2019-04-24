# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::EtdSubmit::CheckMarc do
  subject(:robot) { described_class.new }

  describe '.perform' do
    subject(:perform) { robot.perform(druid) }
    before do
      allow(Etd).to receive(:find).and_return(object)
      stub_request(:get, 'http://lyberservices-dev.stanford.edu/cgi-bin/holdings.php?flexkey=dorbd185gs2259')
        .to_return(status: 200, body: xml)
      allow(object).to receive(:save)
    end

    let(:druid) { 'druid:bd185gs2259' }
    let(:object) { Etd.new(pid: druid) }

    context 'when nodes are empty' do
      let(:xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <titles>
              <record>
                  <key type="flexkey">dormj151qw9093</key>
                  <catkey>8379324</catkey>
                  <home>U-ARCHIVES</home>
                  <current>SHADOW</current>
              </record>
              <record>
                  <key type="flexkey">dormj151qw9093</key>
                  <catkey>8379324</catkey>
                  <home>INTERNET</home>
                  <current>INTERNET</current>
              </record>
          </titles>
        XML
      end

      let(:ng) { Nokogiri::XML(object.datastreams['identityMetadata'].content) }

      it 'adds identityMetadata with the catkey' do
        expect(perform).to be true
        expect(ng.xpath('//otherId[@name="catkey"]').first.text).to eq '8379324'
        expect(object).to have_received(:save)
      end
    end
  end
end
