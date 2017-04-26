require 'spec_helper'

require File.expand_path(File.dirname(__FILE__) + '/../../../robots/accession/shelve')

describe Robots::DorRepo::Accession::Shelve do
  let(:druid) { 'druid:oo000oo0001' }

  it 'includes behavior from LyberCore::Robot' do
    robot = Robots::DorRepo::Accession::Shelve.new
    expect(robot.methods).to include(:work)
  end

  it 'calls .shelve if that method is defined (e.g. item)' do
    object = double(:shelve => true)
    expect(Dor).to receive(:find).with(druid).and_return(object)
    robot = Robots::DorRepo::Accession::Shelve.new
    robot.perform(druid)
  end

  it 'does not call .shelve if that method is not defined (e.g. apo)' do
    object = Object.new
    expect(Dor).to receive(:find).with(druid).and_return(object)
    robot = Robots::DorRepo::Accession::Shelve.new
    expect { robot.perform(druid) }.not_to raise_error(NoMethodError) # we want to be sure that we don't call shelve if the method is not defined
  end

end
