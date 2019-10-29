# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Robots::DorRepo::Accession::RemediateObject do
  let(:druid) { 'druid:oo000oo0001' }
  let(:robot) { described_class.new }

  it 'includes behavior from LyberCore::Robot' do
    expect(robot.methods).to include(:work)
  end

  describe '#perform' do
    it 'gives no error' do
      robot.perform(druid)
    end
  end
end
