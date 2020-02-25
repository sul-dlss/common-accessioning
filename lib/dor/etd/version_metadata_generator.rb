# frozen_string_literal: true

module Dor
  class Etd
    # Create the versionMetadata for etds
    class VersionMetadataGenerator
      # create the versionMetadata
      def self.generate(pid)
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
  end
end
