# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::RemediateObject do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { described_class.new }

  it 'includes behavior from LyberCore::Robot' do
    expect(robot.methods).to include(:work)
  end

  describe '#perform' do
    before do
      expect(Dor).to receive(:find).with(druid).and_return(object)
    end

    context 'on an object where upgrade! is defined' do
      let(:object) { double(:upgrade! => true) }

      it 'calls .upgrade!' do
        robot.perform(druid)
        expect(object).to have_received(:upgrade!)
      end
    end

    context 'on an object where upgrade! is defined' do
      let(:object) { Object.new }

      it 'does not call .upgrade!' do
        # we want to be sure that a NoMethodError is not raised
        expect { robot.perform(druid) }.not_to raise_error
      end
    end
  end
end
