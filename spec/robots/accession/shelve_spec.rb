require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'accession/shelve.rb'

describe Accession::Shelve do
  
  it "is a LyberCore::Robots::Robot" do
    r = Accession::Shelve.new('accessionWF', 'shelve')
    r.should be_a_kind_of LyberCore::Robots::Robot 
  end
  
end