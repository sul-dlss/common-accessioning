# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::EtdSubmit::CatalogStatus do
  subject(:robot) { described_class.new }

  describe '.perform' do
    subject(:perform) { robot.perform(druid) }

    before do
      allow(Dor).to receive(:find).and_return(object)
      allow(Dor::Config.workflow.client).to receive(:workflow_xml).and_return(workflow)
      stub_request(:get, 'http://lyberservices-dev.stanford.edu/cgi-bin/holdings.php?flexkey=dorbd185gs2259')
        .to_return(status: 200, body: xml)
    end

    let(:druid) { 'druid:bd185gs2259' }
    let(:object) { Etd.new(pid: druid) }
    let(:workflow) { '<processes />' }

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

      let(:workflow) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <workflow objectId="druid:mj151qw9093" id="etdAccessionWF">
                <process name="start-accession" lifecycle="inprocess" status="completed" attempts="1" />
                <process name="submit-marc" lifecycle="inprocess" status="waiting" />
                <process name="check-marc" status="waiting" />
                <process name="catalog-status" status="waiting" />
                <process name="descriptive-metadata" status="waiting" />
                <process name="ingest-deposit" status="waiting" />
                <process name="ingest-receipt" status="waiting" />
                <process name="shelve" life-cycle="released" status="waiting" />
                <process name="google-send" status="waiting" />
                <process name="google-confirm" status="waiting" />
                <process name="qoop-send" status="waiting" />
                <process name="qoop-confirm" status="waiting" />
                <process name="cleanup" lifecycle="accessioned" status="waiting" />
                <process name="ingest-complete" lifecycle="archived" status="waiting" />
            </workflow>
        XML
      end

      it 'returns nil' do
        expect(perform).to be_nil
      end
    end
  end
end
