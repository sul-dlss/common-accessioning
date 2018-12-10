# frozen_string_literal: true

require 'spec_helper'

require File.expand_path(File.dirname(__FILE__) + '/../../../robots/accession/provenance_metadata')

describe Robots::DorRepo::Accession::ProvenanceMetadata do
  it 'includes behavior from LyberCore::Robot' do
    robot = Robots::DorRepo::Accession::ProvenanceMetadata.new
    expect(robot.methods).to include(:work)
  end

  it 'has a ROBOT_ROOT' do
    guessed_robot_root = File.expand_path(File.dirname(__FILE__) + '/../../..')
    expect(ROBOT_ROOT).to eql(guessed_robot_root)
  end
end
