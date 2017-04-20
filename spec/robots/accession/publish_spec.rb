require 'spec_helper'

require File.expand_path(File.dirname(__FILE__) + '/../../../robots/accession/publish')

describe Robots::DorRepo::Accession::Publish do
  let(:druid) { 'druid:oo000oo0001' }

  it 'includes behavior from LyberCore::Robot' do
    robot = Robots::DorRepo::Accession::Shelve.new
    expect(robot.methods).to include(:work)
  end

  it 'calls .publish_metadata if that method is defined (e.g. item)' do
    object = double(:publish_metadata => true)
    expect(Dor).to receive(:find).with(druid).and_return(object)
    robot = Robots::DorRepo::Accession::Publish.new
    expect(object).to receive(:publish_metadata)
    robot.perform(druid)
  end

  it 'does not call .publish_metadata if that method is not defined (e.g. apo)' do
    object = Object.new
    expect(Dor).to receive(:find).with(druid).and_return(object)
    robot = Robots::DorRepo::Accession::Publish.new
    expect { robot.perform(druid) }.not_to raise_error(NoMethodError) # we want to be sure that we don't call publish_metadata if the method is not defined
  end

end
