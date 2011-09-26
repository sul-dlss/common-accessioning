require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require File.expand_path(File.dirname(__FILE__) + '/../../../robots/accession/provenance_metadata')

describe Accession::ProvenanceMetadata do
  
  before :all do
    @robot = Accession::ProvenanceMetadata.new
  end
  
  it "inherits behavior from LyberCore::Robots::Robot" do
    @robot.should be_kind_of(LyberCore::Robots::Robot)
  end
  
  it "has a ROBOT_ROOT" do
    guessed_robot_root = File.expand_path(File.dirname(__FILE__) + '/../../..')
    ROBOT_ROOT.should eql(guessed_robot_root)
  end
  

end