module Dor

  class AccessionLite
    
    def self.create apo_druid_id
      puts ">#{apo_druid_id.nil?}<"
      if apo_druid_id.nil? or apo_druid_id == ""
        apo_druid_id = "druid:fg586rn4119"
      end
      Dor::AccessionLite.new.build apo_druid_id
    end

    def build apo_druid_id
      create apo_druid_id
      build_desc_md
      build_rights_md
      build_tech_md
      build_id_md
      init_accession_wf
      puts "Created #{@i.pid}"
      @i.pid
    end

    def create apo_druid_id
      @i = Dor::Item.new
      apo = Dor::AdminPolicyObject.find apo_druid_id
      @i.admin_policy_object = apo
      
      begin
        @i.save
      rescue => e
        # ignore solr error for now
      end
      @i.reload
    end

    def self.reset druid
      Dor::AccessionLite.new.reset druid
    end

    def reset druid
      @i = Dor::Item.find druid
      build_tech_md
      init_accession_wf
    end

    def self.create_assembly
      obj = Dor::AccessionLite.new.build_assembly
    end

    def build_assembly
      create
      build_desc_md
      build_tech_md '/dor/assembly'
      build_rights_md
      build_id_md

      druid = DruidTools::Druid.new(@i.pid, '/dor/assembly')
      md_dir = Pathname.new druid.metadata_dir

      cm_xml =<<-XML
      <?xml version="1.0"?>
      <contentMetadata objectId="#{druid.id}">
          <resource type="image" sequence="1" id="#{druid.id}_1">
              <label>Image 1</label>
              <file preserve="yes" publish="no" shelve="no" id="image111.tif">
              </file>
          </resource>
      </contentMetadata>
      XML

      File.open(md_dir + 'contentMetadata.xml', 'w') do |f|
        f.write cm_xml
      end

      # copy tif to content_dir
      FileUtils.cp(File.join(ROBOT_ROOT, 'spec', 'fixtures', 'image111.tif'), druid.content_dir)

      @i.initialize_workflow 'assemblyWF'

      puts "Created #{@i.pid} for assemblyWF"
      @i.pid
    end

    def build_desc_md
      mods_xml =<<-XML
      <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
        <titleInfo>
          <title>Dummy title</title>
          </titleInfo>
      </mods>
      XML
      @i.datastreams['descMetadata'].content = mods_xml
      @i.datastreams['descMetadata'].save
    end

    def build_rights_md
      r_xml =<<-XML
      <rightsMetadata objectId="#{@i.pid}">
        <copyright>
          <human>(c) Copyright 2010 by Sebastian Jeremias Osterfeld</human>
        </copyright>
        <access type="discover">
          <machine>
            <world></world>
          </machine>
        </access>
        <access type="read">
          <machine>
            <group>stanford:stanford</group>
          </machine>
        </access>
        <use>
          <machine type="creativeCommons">by-sa</machine>
          <human type="creativeCommons">CC Attribution Share Alike license</human>
        </use>
      </rightsMetadata>
      XML
      @i.datastreams['rightsMetadata'].content = r_xml
      @i.datastreams['rightsMetadata'].save
    end

    def build_tech_md base = Dor::Config.stacks.local_workspace_root
      xml =<<-XML
      <technicalMetadata xmlns:jhove="http://hul.harvard.edu/ois/xml/ns/jhove" xmlns:mix="http://www.loc.gov/mix/v10" xmlns:textmd="info:lc/xmlns/textMD-v3" objectId="#{@i.pid}" datetime="2014-01-27T21:35:32Z">
      </technicalMetadata>
      XML
      druid = DruidTools::Druid.new(@i.pid, base)
      druid.metadata_dir      # build the metadata dir
      File.open(druid.metadata_dir + "/technicalMetadata.xml", 'w') do |f|
        f.write xml
      end
    end

    def build_id_md
      @i.identityMetadata.add_value 'objectType', 'item'
      @i.identityMetadata.save
    end

    def init_accession_wf
      wf_xml = IO.read(File.join(ROBOT_ROOT, 'config', 'workflows', 'accessionWF', 'lite.xml'))
      Dor::WorkflowService.create_workflow 'dor', @i.pid, 'accessionWF', wf_xml
    end

  end
end