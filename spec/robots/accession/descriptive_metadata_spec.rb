# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::DescriptiveMetadata do
  subject(:robot) { described_class.new }

  it 'includes behavior from LyberCore::Robot' do
    expect(robot.methods).to include(:work)
  end

  describe '#perform' do
    subject(:perform) { robot.perform(druid) }

    let(:druid) { 'druid:ab123cd4567' }

    context 'on an item' do
      before do
        # rubocop:disable Lint/HandleExceptions
        begin
          Dor::Item.find(druid).destroy
        rescue ActiveFedora::ObjectNotFoundError
          # This repo is already clean
        end
        # rubocop:enable Lint/HandleExceptions

        stub_request(:get, 'https://example.com/workflow/objects/druid:ab123cd4567/workflows')
          .to_return(status: 200, body: '', headers: {})
        stub_request(:get, 'https://example.com/workflow/dor/objects/druid:ab123cd4567/lifecycle')
          .to_return(status: 200, body: '', headers: {})
        stub_request(:get, 'http://example.edu/catalog/mods/?catkey=12345')
          .to_return(status: 200, body: xml)
      end

      let!(:object) { Dor::Item.create!(pid: druid, catkey: '12345') }
      let(:xml) { '<mods><titleInfo><title>Hello</title></titleInfo></mods>' }

      it 'builds a datastream from the remote service call' do
        perform
        expect(object.reload.descMetadata.content).to be_equivalent_to xml
      end
    end
  end
end
