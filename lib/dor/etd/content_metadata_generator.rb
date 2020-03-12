# frozen_string_literal: true

module Dor
  class Etd
    # Create the contentMetadata for etds
    class ContentMetadataGenerator
      def self.generate(etd)
        new(etd).generate
      end

      def initialize(etd)
        @etd = etd
      end

      # create the content metadata xml
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
      def generate
        builder = Nokogiri::XML::Builder.new do |xml|
          resource_index = 0
          resource_prefix = pid.sub('druid:', '')
          xml.contentMetadata(type: 'file', objectId: pid) do
            # main pdf
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
              supplemental_file_size = props_ds.term_values(:size).first
              xml.resource(id: "#{resource_prefix}_#{resource_index += 1}", type: 'supplement', sequence: sequence + 1, objectId: supplemental_file.pid) do
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
              permission_file_size = props_ds.term_values(:size).first
              xml.resource(id: "#{resource_prefix}_#{resource_index += 1}", type: 'permissions', objectId: permission_file.pid) do
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

      def content_path
        druid = DruidTools::Druid.new(pid, Settings.sdr.local_workspace_root)
        druid.content_dir(false)
      end

      # TODO: temporary fix for unknown file types
      # We should use `file -ib #{file_path}` to determine mime type
      # See ETD-418
      def determine_mime_type(file_name)
        type = MIME::Types.type_for(file_name)
        return 'application/octet-stream' if type.nil? || type.first.nil?

        type.first.content_type
      end

      attr_reader :etd
      delegate :supplemental_files, :permission_files, :pid, to: :etd

      def main_pdf
        @main_pdf ||= etd.parts[0]
      end
    end
  end
end
