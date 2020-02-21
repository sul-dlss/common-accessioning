# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::EtdSubmit::CatalogStatus do
  subject(:robot) { described_class.new }

  describe '.perform' do
    subject(:perform) { robot.perform(druid) }

    before do
      allow(Dor).to receive(:find).and_return(object)
      allow(robot.workflow_service).to receive(:workflow_status).and_return(status)
      stub_request(:get, 'http://lyberservices-dev.stanford.edu/cgi-bin/holdings.php?flexkey=dorbd185gs2259')
        .to_return(status: 200, body: xml)
    end

    let(:druid) { 'druid:bd185gs2259' }
    let(:object) { Etd.new(pid: druid) }
    let(:status) { nil }

    context 'when nodes are empty' do
      let(:xml) { '<xml />' }

      it 'returns waiting' do
        expect(perform.status).to eq 'waiting'
      end
    end

    context 'when current_location == home_location' do
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

      it 'returns done' do
        expect(perform).to be true
      end
    end

    context 'when current_location != home_location' do
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
                  <current>SHADOW</current>
              </record>
          </titles>
        XML
      end

      let(:status) { 'waiting' }

      it 'returns nil' do
        expect(perform).to be_nil
      end
    end
  end
end
