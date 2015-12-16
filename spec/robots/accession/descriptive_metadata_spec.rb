require 'spec_helper'

require File.expand_path(File.dirname(__FILE__) + '/../../../robots/accession/descriptive_metadata')

describe Robots::DorRepo::Accession::DescriptiveMetadata do
  it 'includes behavior from LyberCore::Robot' do
    robot = Robots::DorRepo::Accession::DescriptiveMetadata.new
    expect(robot.methods).to include(:work)
  end

  it 'has a ROBOT_ROOT' do
    guessed_robot_root = File.expand_path(File.dirname(__FILE__) + '/../../..')
    ROBOT_ROOT.should eql(guessed_robot_root)
  end
end
