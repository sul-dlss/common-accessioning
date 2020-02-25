# frozen_string_literal: true

module Dor
  class Etd
    # Create the rightsMetadata for etds
    class RightsMetadataGenerator
      def self.generate(etd)
        new(etd).generate
      end

      def initialize(etd)
        @etd = etd
      end

      # create the rights metadata xml
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
      def generate
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.rightsMetadata(objectId: pid) do
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
            release_date = etd.etd_embargo_date
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

      private

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

      def props_ds
        etd.datastreams['properties']
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

      attr_reader :etd
      delegate :pid, to: :etd
    end
  end
end
