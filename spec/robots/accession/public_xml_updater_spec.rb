require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../robots/accession/public_xml_updater')

describe Accession::PublicXmlUpdater do
  
  before(:each) do
    @bot = Accession::PublicXmlUpdater.new
    @real_msg = <<-EOXML
      <entry xmlns="http://www.w3.org/2005/Atom" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:fedora-types="http://www.fedora.info/definitions/1/0/types/">
        <id>urn:uuid:27347ff0-5301-4d97-9bda-719dc6de2eb7</id>
        <updated>2011-10-25T23:27:07.099Z</updated>
        <author>
          <name>fedoraAdmin</name>
          <uri>http://fedora-dev.stanford.edu:8080/fedora</uri>
        </author>
        <title type="text">modifyDatastreamByValue</title>
        <category term="druid:td053mv5518" scheme="fedora-types:pid" label="xsd:string"></category>
        <category term="rightsMetadata" scheme="fedora-types:dsID" label="xsd:string"></category>
        <category term="" scheme="fedora-types:altIDs" label="fedora-types:ArrayOfString"></category>
        <category term="Rights Metadata" scheme="fedora-types:dsLabel" label="xsd:string"></category>
        <category term="" scheme="fedora-types:formatURI" label="xsd:string"></category>
        <category term="[OMITTED]" scheme="fedora-types:dsContent" label="xsd:base64Binary"></category>
        <category term="Disabled" scheme="fedora-types:checksumType" label="xsd:string"></category>
        <category term="null" scheme="fedora-types:checksum" label="xsd:string"></category>
        <category term="null" scheme="fedora-types:logMessage" label="xsd:string"></category>
        <category term="false" scheme="fedora-types:force" label="xsd:boolean"></category>
        <summary type="text">druid:td053mv5518</summary>
        <content type="text">2011-10-25T23:27:07.098Z</content>
        <category term="32.1" scheme="info:fedora/fedora-system:def/view#version"></category>
        <category term="info:fedora/fedora-system:ATOM-APIM-1.0" scheme="http://www.fedora.info/definitions/1/0/types/formatURI"></category>
      </entry>
    EOXML
  end
  
  it "intializes with @host from Dor::Config" do
    @bot.host.should =~ /^dor-/
  end
  
  describe "#correct_datastream?" do

    it "checks if the incoming message deals with datastreams we are interested in" do
      @bot.msg = Nokogiri::XML(@real_msg)
      @bot.correct_datastream?.should be
    end
  end
  
  describe "#process_message?" do
    it "checks if the object has reached the lifecycle milestone of 'released', publishes the metadata, and sets disseminationWF::publish to completed" do
      @bot.msg = Nokogiri::XML(@real_msg)
      Dor::WorkflowService.should_receive(:get_lifecycle).with('dor', 'druid:td053mv5518', 'released').and_return(Time.now)
      Dor::WorkflowService.should_receive(:update_workflow_status).with('dor', 'druid:td053mv5518','disseminationWF','publish','completed', {:elapsed => kind_of(Numeric), :lifecycle => 'published'})

      mock_item = mock('item')
      Dor::Item.should_receive(:load_instance).and_return(mock_item)
      mock_item.should_receive(:publish_metadata)
      
      @bot.process_message
    end

    it "checks if the object has reached the lifecycle milestone of 'released' or 'published', publishes the metadata, and sets disseminationWF::publish to completed" do
      @bot.msg = Nokogiri::XML(@real_msg)
      Dor::WorkflowService.should_receive(:get_lifecycle).with('dor', 'druid:td053mv5518', 'released').and_return(nil)
      Dor::WorkflowService.should_receive(:get_lifecycle).with('dor', 'druid:td053mv5518', 'published').and_return(Time.now)
      Dor::WorkflowService.should_receive(:update_workflow_status).with('dor', 'druid:td053mv5518','disseminationWF','publish','completed', {:elapsed => kind_of(Numeric), :lifecycle => 'published'})

      mock_item = mock('item')
      Dor::Item.should_receive(:load_instance).and_return(mock_item)
      mock_item.should_receive(:publish_metadata)
      
      @bot.process_message
    end
  end
  
end