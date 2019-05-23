# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::ProvenanceMetadata do
  let(:robot) { described_class.new }

  it 'includes behavior from LyberCore::Robot' do
    expect(robot.methods).to include(:work)
  end

  it 'has a ROBOT_ROOT' do
    guessed_robot_root = File.expand_path(File.dirname(__FILE__) + '/../../..')
    expect(ROBOT_ROOT).to eql(guessed_robot_root)
  end

  describe 'build_datastream' do
    subject(:build) { robot.send(:build_datastream, item, workflow_id, event_text) }

    let(:workflow_id) { 'accessionWF' }
    let(:event_text) { 'DOR Common Accessioning' }

    context 'on an existing object' do
      let(:item) { instantiate_fixture('druid:ab123cd4567', Dor::Item) }

      it 'builds the provenanceMetadata datastream' do
        expect(item.datastreams['provenanceMetadata'].ng_xml.to_s).to be_equivalent_to('<xml/>')
        build
        expect(item.datastreams['provenanceMetadata'].ng_xml.to_s).not_to be_equivalent_to('<xml/>')
      end
    end

    context 'on a new object' do
      let(:item) { Dor::Item.new(pid: druid) }
      let(:druid) { 'druid:aa123bb4567' }

      before do
        # stub fedora
        allow(item.inner_object).to receive(:repository).and_return(double('frepo').as_null_object)
      end

      it 'generates workflow provenance' do
        build
        wp_xml = item.datastreams['provenanceMetadata'].ng_xml
        expect(wp_xml).to be_instance_of(Nokogiri::XML::Document)
        expect(wp_xml.root.name).to eql('provenanceMetadata')
        expect(wp_xml.root[:objectId]).to eql(druid)
        agent = wp_xml.xpath('/provenanceMetadata/agent').first
        expect(agent.name).to eql('agent')
        expect(agent[:name]).to eql('DOR')
        what = agent.first_element_child
        expect(what.name).to eql('what')
        expect(what[:object]).to eql(druid)
        event = what.first_element_child
        expect(event.name).to eql('event')
        expect(event[:who]).to eql("DOR-#{workflow_id}")
        expect(event.content).to eql(event_text)
      end
    end
  end
end
