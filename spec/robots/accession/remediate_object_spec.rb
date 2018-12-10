# frozen_string_literal: true

require 'spec_helper'

require File.expand_path(File.dirname(__FILE__) + '/../../../robots/accession/remediate_object')

describe Robots::DorRepo::Accession::RemediateObject do
  let(:druid) { 'druid:oo000oo0001' }

  it 'includes behavior from LyberCore::Robot' do
    robot = Robots::DorRepo::Accession::RemediateObject.new
    expect(robot.methods).to include(:work)
  end

  it 'calls .upgrade! if that method is defined' do
    object = double(:upgrade! => true)
    expect(Dor).to receive(:find).with(druid).and_return(object)
    robot = Robots::DorRepo::Accession::RemediateObject.new
    robot.perform(druid)
  end

  it 'does not call .upgrade! if that method is not defined' do
    object = Object.new
    expect(Dor).to receive(:find).with(druid).and_return(object)
    robot = Robots::DorRepo::Accession::RemediateObject.new
    expect { robot.perform(druid) }.not_to raise_error(NoMethodError) # we want to be sure that we don't call upgrade! if the method is not defined
  end

end
