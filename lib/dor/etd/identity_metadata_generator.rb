# frozen_string_literal: true

require 'uuidtools'
require 'active_support/core_ext/object/blank.rb'

module Dor
  class Etd
    # Create the identityMetadata for etds
    class IdentityMetadataGenerator
      def self.generate(etd)
        new(etd).generate
      end

      attr_reader :etd
      delegate :pid, to: :etd

      def initialize(etd)
        @etd = etd
      end

      # create the identity metadata xml
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
      def generate
        builder = Nokogiri::XML::Builder.new do |xml|
          old_identity_ds = etd.identityMetadata
          old_identity_doc = Nokogiri::XML(old_identity_ds.content) unless old_identity_ds.new?
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
              unless old_identity_doc.nil?
                # we expect catkey to be present in previous xml when it exists
                catkey = old_identity_doc.at_xpath('//catkey')
                catkey = old_identity_doc.at_xpath("//otherId[@name='catkey']") if catkey.nil?
                xml.text(catkey.text)
              end
            end
            xml.otherId(name: 'uuid') do
              if old_identity_doc.nil?
                xml.text(UUIDTools::UUID.timestamp_create)
              else
                uuid = old_identity_doc.at_xpath("//otherId[@name='uuid']")
                # If there's an old UUID, set it as the value, otherwise, create a new one
                if uuid&.text.present?
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

      private

      def props_ds
        etd.datastreams['properties']
      end
    end
  end
end
