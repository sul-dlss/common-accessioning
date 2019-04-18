# frozen_string_literal: true

require 'nokogiri'
require 'uuidtools'
require 'active_support/core_ext'

module EtdMetadata
  # create a datastream in the repository for the given etd object
  def populate_datastream(ds_name)
    label = case ds_name
            when 'identityMetadata' then 'Identity Metadata'
            when 'contentMetadata' then 'Content Metadata'
            when 'rightsMetadata' then 'Rights Metadata'
            when 'versionMetadata' then 'Version Metadata'
            else ''
            end
    metadata = case ds_name
               when 'identityMetadata' then generate_identity_metadata_xml
               when 'contentMetadata' then generate_content_metadata_xml
               when 'rightsMetadata' then generate_rights_metadata_xml
               when 'versionMetadata' then generate_version_metadata_xml
               end
    return if metadata.nil?

    populate_datastream_in_repository(ds_name, label, metadata)
  end

  # create a datastream for the given etd object with the given datastream name, label, and metadata blob
  def populate_datastream_in_repository(ds_name, label, metadata)
    attrs = { mimeType: 'application/xml', dsLabel: label, content: metadata }
    datastream = ActiveFedora::Datastream.new(inner_object, ds_name, attrs)
    datastream.controlGroup = 'M'
    datastream.save
  end

  def content_path
    druid = DruidTools::Druid.new(pid, Dor::Config.sdr.local_workspace_root)

    druid.content_dir(false)
  end

  # create the identity metadata xml datastream
  #
  #   <identityMetadata>
  #     <objectId>druid:rt923jk342</objectId>                                   <-- Fedora PID
  #     <objectType>item</objectType>                                           <-- Supplied fixed value
  #     <objectLabel>value from Fedora header</objectLabel>                     <-- from Fedora header
  #     <objectCreator>DOR</objectCreator>                                      <-- Supplied fixed value
  #     <otherId name="dissertationid">0000000012</otherId>                     <-- per Registrar, from ETD propertied <dissertationid>
  #     <otherId name="catkey">129483625</otherId>                              <-- added after Symphony record is created. Can be found in DC
  #     <otherId name="uuid">7f3da130-7b02-11de-8a39-0800200c9a66</otherId>     <-- DOR assigned (omit if not present)
  #     <agreementId>druid:ct692vv3660</agreementId>                            <-- fixed pre-assigned value, use the value shown here for ETDs
  #     <tag>ETD : Dissertation | Thesis</tag>                                  <-- set of tags *
  #   </identityMetadata>
  #
  def generate_identity_metadata_xml
    builder = Nokogiri::XML::Builder.new do |xml|
      props_ds = datastreams['properties']
      old_identity_ds = datastreams['identityMetadata']
      old_identity_doc = Nokogiri::XML(old_identity_ds.content) unless old_identity_ds.nil?
      xml.identityMetadata do
        xml.objectId do
          xml.text(pid)
        end
        xml.objectType do
          xml.text('item')
        end
        xml.objectLabel do
          xml.text('')
        end
        xml.objectCreator do
          xml.text('DOR')
        end
        xml.otherId(name: 'dissertationid') do
          dissertation_id = props_ds.dissertation_id.first
          xml.text(dissertation_id)
        end
        xml.otherId(name: 'catkey') do
          unless old_identity_ds.nil?
            catkey = old_identity_doc.at_xpath('//catkey')
            catkey = old_identity_doc.at_xpath("//otherId[@name='catkey']") if catkey.nil?
            xml.text(catkey.text)
          end
        end
        # TODO: generate uuid
        xml.otherId(name: 'uuid') do
          if old_identity_ds.nil?
            xml.text(UUIDTools::UUID.timestamp_create)
          else
            uuid = old_identity_doc.at_xpath("//otherId[@name='uuid']")
            # If there's an old UUID, set it as the value, otherwise, create a new one
            if !uuid.nil? && uuid.text != ''
              xml.text(uuid.text)
            else
              xml.text(UUIDTools::UUID.timestamp_create)
            end
          end
        end
        xml.agreementId do
          xml.text('druid:ct692vv3660')
        end
        xml.objectAdminClass do
          xml.text('ETDs')
        end
        xml.tag do
          etd_type = props_ds.etd_type.first
          xml.text("ETD : #{etd_type}")
        end
      end
    end
    builder.to_xml
  end

  # TODO: temporary fix for unknown file types
  # We should use `file -ib #{file_path}` to determine mime type
  # See ETD-418
  def determine_mime_type(file_name)
    type = MIME::Types.type_for(file_name)
    return 'application/octet-stream' if type.nil? || type.first.nil?

    type.first.content_type
  end

  # create the content metadata xml datastream
  #
  #   <contentMetadata type="etd" objectId="druid:rt923jk342">
  #     <resource id="main" type="main-original" data="content">
  #       <attr name="label">Body of dissertation (as submitted)</attr>
  #       <file id="mydissertation.pdf" mimetype="application/pdf" size="758621" shelve="yes" deliver="no" preserve="yes" />
  #     </resource>
  #     <resource id="main" type="main-augmented" data="content" objectId="druid:ck234ku2334">
  #       <attr name="label">Body of dissertation</attr>
  #       <file id="mydissertation-augmented.pdf" mimetype="application/pdf" size="751418" shelve="yes" deliver="yes" preserve="yes" />
  #     </resource>
  #     <resource id="supplement" type="supplement" data="content" sequence="1" objectId="druid:pt747ce6889">
  #       <attr name="label">Full experimental data</attr>
  #       <file id="datafile.xls" mimetype="application/ms-excel" size="83418" shelve="yes" deliver="yes" preserve="yes" />
  #     </resource>
  #     <resource id="permissions" type="permissions" data="content" objectId="druid:wb711pm9935">
  #       <attr name="label">Permission from the artist</attr>
  #       <file id="xyz-permission.txt" mimetype="application/text" size="341" shelve="yes" deliver="no" preserve="yes" />
  #     </resource>
  #   </contentMetadata>
  #
  def generate_content_metadata_xml
    # TODO: add checksums to file elements here
    # <file mimetype="application/xml" format="TEXT" size="1898705" id="technicalMetadata.xml" publish="no" shelve="no" preserve="yes">
    #    <checksum type="SHA-1">3f2d9b8e280ae143fb426e052e59705bcbb19e3b</checksum>
    #    <checksum type="MD5">cd7506ca9878884d6148844011b2864d</checksum>
    # </file>
    builder = Nokogiri::XML::Builder.new do |xml|
      resource_index = 0
      resource_prefix = pid.sub('druid:', '')
      xml.contentMetadata(type: 'file', objectId: pid) do
        # main pdf
        main_pdf = parts[0]
        props_ds = main_pdf.datastreams['properties']
        main_pdf_file_name = props_ds.file_name.first
        main_pdf_file_size = props_ds.term_values(:size).first
        xml.resource(id: "#{resource_prefix}_#{resource_index += 1}", type: 'main-original') do
          xml.attr(name: 'label') do
            xml.text('Body of dissertation (as submitted)')
          end
          xml.file(id: main_pdf_file_name, mimetype: 'application/pdf', size: main_pdf_file_size, shelve: 'yes', publish: 'no', preserve: 'yes') do
            md5, sha1 = generate_checksums(main_pdf_file_name)
            xml.checksum md5, type: 'md5'
            xml.checksum sha1, type: 'sha1'
          end
        end
        # augmented pdf
        props_ds = main_pdf.datastreams['properties']
        main_pdf_file_name = props_ds.file_name.first
        main_pdf_file_size = props_ds.term_values(:size).first
        augmented_pdf_file_name = main_pdf_file_name.gsub(/\.pdf/i, '-augmented.pdf')
        augmented_pdf_file_size = File.size?(File.join(content_path, augmented_pdf_file_name))
        xml.resource(id: "#{resource_prefix}_#{resource_index += 1}", type: 'main-augmented', objectId: main_pdf.pid) do
          xml.attr(name: 'label') do
            xml.text('Body of dissertation')
          end
          xml.file(id: augmented_pdf_file_name, mimetype: 'application/pdf', size: augmented_pdf_file_size, shelve: 'yes', publish: 'yes', preserve: 'yes') do
            md5, sha1 = generate_checksums(augmented_pdf_file_name)
            xml.checksum md5, type: 'md5'
            xml.checksum sha1, type: 'sha1'
          end
        end
        # supplemental files
        supplemental_files.each_with_index do |supplemental_file, sequence|
          props_ds = supplemental_file.datastreams['properties']
          supplemental_file_name = props_ds.file_name.first
          supplemental_file_mimetype = determine_mime_type(supplemental_file_name)
          supplemental_file_label = props_ds.term_values(:label).first
          supplemental_file_size = props_ds.term_values(:size).first
          xml.resource(id: "#{resource_prefix}_#{resource_index += 1}", type: 'supplement', sequence: sequence + 1, objectId: supplemental_file.pid) do
            xml.attr(name: 'label') do
              xml.text(supplemental_file_label)
            end
            xml.file(id: supplemental_file_name, mimetype: supplemental_file_mimetype, size: supplemental_file_size, shelve: 'yes', publish: 'yes', preserve: 'yes') do
              md5, sha1 = generate_checksums(supplemental_file_name)
              xml.checksum md5, type: 'md5'
              xml.checksum sha1, type: 'sha1'
            end
          end
        end
        # permission files
        permission_files.each_with_index do |permission_file, _sequence|
          props_ds = permission_file.datastreams['properties']
          permission_file_name = props_ds.file_name.first
          permission_file_mimetype = determine_mime_type(permission_file_name)
          permission_file_label = props_ds.term_values(:label).first
          permission_file_size = props_ds.term_values(:size).first
          xml.resource(id: "#{resource_prefix}_#{resource_index += 1}", type: 'permissions', objectId: permission_file.pid) do
            xml.attr(name: 'label') do
              xml.text(permission_file_label)
            end
            xml.file(id: permission_file_name, mimetype: permission_file_mimetype, size: permission_file_size, shelve: 'yes', publish: 'no', preserve: 'yes') do
              md5, sha1 = generate_checksums(permission_file_name)
              xml.checksum md5, type: 'md5'
              xml.checksum sha1, type: 'sha1'
            end
          end
        end
      end
    end
    builder.to_xml
  end

  # Generates md5 and sha1 from the passed in file_name, for file that should exist in the druid-tree for this object
  # @param [String] file_name Name of the file
  # @return [Array] a[0] = md5; a[1] = sha1
  def generate_checksums(file_name)
    path = File.join(content_path, file_name)
    md5 = Digest::MD5.file(path).hexdigest
    sha1 = Digest::SHA1.file(path).hexdigest
    [md5, sha1]
  end

  # create the rights metadata xml datastream
  #
  #   <rightsMetadata objectId="druid:rt923jk342">
  #     <copyright>
  #       <human>(c) Copyright [reg approval year] by [student name]</human>
  #     </copyright>
  #     <access type="discover">                                        <--- this block is static across ETDs; all ETDs are discoverable
  #       <machine>
  #         <world />
  #       </machine>
  #     </access>
  #     <access type="read">                                            <--- include this block after an object has been "released"
  #       <machine>
  #         <group>stanford:stanford</group> -OR- <world />             <--- for Stanford-only access or world/public visibility
  #         <embargoReleaseDate>2011-03-01</embargoReleaseDate>         <--- if embargoed, date calculated from release date
  #       </machine>
  #     </access>
  #     <use>
  #       <machine type="creativeCommons" type="code">value</machine>   <--- if a license is selected
  #     <use>
  #   </rightsMetadata>
  #
  def generate_rights_metadata_xml
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.rightsMetadata(objectId: pid) do
        props_ds = datastreams['properties']
        submit_dt = Time.at(props_ds.submit_date.first.to_i)
        copyright_year = submit_dt.year.to_s
        student_name = props_ds.name.first
        xml.copyright do
          xml.human do
            formatted_student_name = parse_name(student_name)
            xml.text("(c) Copyright #{copyright_year} by #{formatted_student_name}")
          end
        end
        xml.access(type: 'discover') do
          xml.machine do
            xml.world
          end
        end

        # Generate the rights access block
        release_date = get_embargo_date
        visibility = props_ds.external_visibility.first
        generate_rights_access_block(xml, release_date, visibility)

        cc_license_type = props_ds.cclicensetype.first
        cc_code = props_ds.cclicense.first
        cc_license = case cc_code
                     when '1' then 'by'
                     when '2' then 'by-sa'
                     when '3' then 'by-nd'
                     when '4' then 'by-nc'
                     when '5' then 'by-nc-sa'
                     when '6' then 'by-nc-nd'
                     else 'none'
                     end
        unless cc_license.nil? && cc_license_type.nil?
          xml.use do
            xml.machine(type: 'creativeCommons') do
              xml.text(cc_license)
            end
            xml.human(type: 'creativeCommons') do
              xml.text(cc_license_type)
            end
          end
        end
      end
    end
    builder.to_xml
  end

  def generate_rights_access_block(xml, release_date, visibility)
    access_type = 'stanford'
    access_type = 'world' if (visibility == '100') && (!release_date.nil? && release_date.past?)
    xml.access(type: 'read') do
      xml.machine do
        if access_type.eql? 'stanford'
          xml.group do
            xml.text('stanford')
          end
          if !release_date.nil? && release_date > Time.new
            xml.embargoReleaseDate do
              xml.text(release_date.strftime('%Y-%m-%d'))
            end
          end
        else
          xml.world
        end
      end
    end
  end

  def parse_name(name_str)
    if /,/.match?(name_str)
      name_str =~ /([^,\r\n]*),\s*(.*)/
      last = Regexp.last_match(1)
      first = Regexp.last_match(2)
      name_str = "#{first} #{last}"
    end
    name_str
  end

  # create the versionMetadata datastream
  def generate_version_metadata_xml
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.versionMetadata(objectId: pid) do
        xml.version(versionId: '1', tag: '1.0.0') do
          xml.description do
            xml.text('Initial Version')
          end
        end
      end
    end
    builder.to_xml
  end
end
