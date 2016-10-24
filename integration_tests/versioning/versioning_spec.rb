require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'druid_tools'
require 'assembly-utils'

describe 'Digital Object Versioning' do

  before(:all) do
    WfItem = Struct.new(:druid)
  end

  let(:fixture_base) { File.expand_path(File.dirname(__FILE__) + '/../fixtures/versioning') }
  let(:pid) { 'druid:oo000vt0001' }
  let(:obj) { Dor.find pid }
  let(:wfi) { WfItem.new(pid) }  # Simulates workflow_item passed to the robots

  before(:each) do
    # Remove old object from test environment
    nuke
    # Load fixture foxml into fedora
    fixture_dir = fixture_base + '/' + fixture_name
    loader = ActiveFedora::FixtureLoader.new(fixture_dir)
    ActiveFedora::FixtureLoader.import_to_fedora(loader.filename_for_pid('druid:oo000vt0001'))

    # Create workspace directory, add content and metadata
    d = DruidTools::Druid.new pid, Dor::Config.stacks.local_workspace_root

    d.mkdir
    d.content_dir
    d.metadata_dir
    Dir.chdir(fixture_dir) do
      content = Dir.glob('*').reject{|f| f =~ /xml$/ }
      content.each {|cf| FileUtils.cp( File.join(fixture_dir, cf), d.content_dir)}

      md = Dir.glob('*.xml').reject{|f| f == 'druid_oo000vt0001.xml' }
      md.each {|mf| FileUtils.cp( File.join(fixture_dir, mf), d.metadata_dir)}
    end
  end

  def run_robots
    # Run robots
    cmr = Accession::ContentMetadata.new
    cmr.process_item wfi

    dmr = Accession::DescriptiveMetadata.new
    dmr.process_item wfi

    rmr = Accession::RightsMetadata.new
    rmr.process_item wfi

    tmr = Accession::TechnicalMetadata.new
    tmr.process_item wfi

    obj.build_provenanceMetadata_datastream('accessionWF', 'DOR Common Accessioning completed')
    obj.upgrade!
    obj.shelve
    obj.publish_metadata
    obj.sdr_ingest_transfer('')
  end

  def nuke
    # Nuke from test environment
    old = Dor.find pid rescue nil
    old.cleanup unless old.nil?
    Assembly::Utils.cleanup_object pid, [:stacks, :dor]
    Assembly::Utils.delete_all_workflows pid
    Dor::Config.workflow.client.delete_workflow 'sdr', pid, 'sdrIngestWF'
  end

  def copy_supp_file_1_to_stacks
    druid = DruidTools::Druid.new(pid, Dor::Config.stacks.local_workspace_root)
    remote_storage_dir = Dor::DigitalStacksService.stacks_storage_dir(pid)
    Net::SFTP.start(Dor::Config.stacks.host, Dor::Config.stacks.user, :auth_methods => ['publickey']) do |sftp|
      sftp.session.exec! "mkdir -p #{remote_storage_dir}"
      old_file = File.join(fixture_base, 'test1', 'Supplement 1 - Glossary of Terms.pptx')
      upload = sftp.upload(old_file, File.join(remote_storage_dir, 'Supplement 1 - Glossary of Terms.pptx'))
      upload.wait
    end
  end

  context 'object creation' do
    let(:fixture_name) { 'test1' }

    it 'first pass of common-accessioning creates version 1' do
      run_robots
      # Check for version

    end
  end

  context 'version changes' do

    let(:pid_home) { pid.split(':')[1] }

    before(:each) do
      # mock call to get lifecycle so that object is 'accessioned' but not yet 'opened'
      Dor::Config.workflow.client.should_receive(:get_lifecycle).with('dor', pid, 'accessioned').and_return(true)
      Dor::Config.workflow.client.should_receive(:get_active_lifecycle).with('dor', pid, 'opened').twice.and_return(nil)

      obj.open_new_version
      copy_to_stacks
      run_robots
    end

    context 'test2' do
      let(:fixture_name) { 'test2' }
      let(:copy_to_stacks) { false }

      it 'handles adding a new file' do
        content_md = obj.datastreams['contentMetadata']
        content_md.ng_xml.at_xpath("//resource[@id='permissions']").should be
        content_md.ng_xml.xpath('//resource').size.should == 5

        tech_md = obj.datastreams['technicalMetadata']
        tech_md.ng_xml.xpath("//file[@id='Permission from Houghton Mifflin.pdf']").size.should == 1

        prov_md = obj.datastreams['provenanceMetadata']
        prov_md.ng_xml.xpath('/agent/what/event').size.should == 1

        # Check of the bagit directory for new file
        added_file = Pathname(Dor::Config.sdr.local_export_home).join(pid_home, 'data', 'content', 'Permission from Houghton Mifflin.pdf')
        added_file.should exist
      end
    end

    context 'test3' do
      let(:fixture_name) { 'test3' }
      let(:copy_to_stacks) {
        copy_supp_file_1_to_stacks
        true
      }

      it 'handles deleting a file' do
        content_md = obj.datastreams['contentMetadata']
        content_md.ng_xml.xpath('//resource').size.should == 3

        added_file = Pathname(Dor::Config.sdr.local_export_home).join(pid_home, 'data', 'content', 'Supplement 1 - Glossary of Terms.pptx')
        added_file.should_not exist
      end
    end

    context 'test4' do
      let(:fixture_name) { 'test4' }
      let(:copy_to_stacks) { false }

      it 'handles replacing a file' do
        content_md = obj.datastreams['contentMetadata']
        content_md.ng_xml.xpath('//resource').size.should == 4

        added_file = Pathname(Dor::Config.sdr.local_export_home).join(pid_home, 'data', 'content', 'HEBARD DISSERTATION 8-26 1226-augmented.pdf')
        added_file.should exist
      end
    end

    context 'test5' do
      let(:test_5_new_file) { 'Supplement 1 - New Glossary of Terms.pptx' }
      let(:fixture_name) { 'test5' }
      let(:copy_to_stacks) {
        copy_supp_file_1_to_stacks
        true
      }

      it 'handles renaming a file' do
        content_md = obj.datastreams['contentMetadata']
        content_md.ng_xml.at_xpath("//file[@id='Supplement 1 - New Glossary of Terms.pptx']").should be

        tech_md = obj.datastreams['technicalMetadata']
        tech_md.ng_xml.at_xpath("//file[@id='Supplement 1 - New Glossary of Terms.pptx']").should be

        v_md = obj.datastreams['versionMetadata']
        v_md.ng_xml.xpath('//version').size.should == 2

        # Renames do not produce content directories to send over
        Pathname(Dor::Config.sdr.local_export_home).join(pid_home, 'data', 'content', test_5_new_file).should_not exist
      end
    end

    context 'test6' do
       let(:fixture_name) { 'test6' }
       let(:copy_to_stacks) { false }

       it 'handles rearranging files' do
         content_md = obj.datastreams['contentMetadata']
         content_md.ng_xml.at_xpath("//resource[@sequence='3' and @id='supplement2']").should be
         content_md.ng_xml.at_xpath("//resource[@sequence='4' and @id='supplement1']").should be

         Pathname(Dor::Config.sdr.local_export_home).join(pid_home, 'data', 'content').should_not exist
       end
     end

     context 'test7' do
       let(:fixture_name) { 'test7' }
       let(:copy_to_stacks) { false }

       it 'handles metadata-only changes' do
         content_md = obj.datastreams['contentMetadata']

         Pathname(Dor::Config.sdr.local_export_home).join(pid_home, 'data', 'content').should_not exist
       end
     end

  end

end
