require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'accession/remediate_object.rb'

describe Accession::RemediateObject do
  
  it "is a LyberCore::Robots::Robot" do
    r = Accession::RemediateObject.new
    r.should be_a_kind_of LyberCore::Robots::Robot 
  end
  
end