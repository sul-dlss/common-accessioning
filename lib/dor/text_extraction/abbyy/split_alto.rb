# frozen_string_literal: true

module Dor
  module TextExtraction
    module Abbyy
      # Split ALTO file into page files
      class SplitAlto
        attr_reader :alto_path, :doc

        def initialize(alto_path:)
          @alto_path = alto_path
          @doc = Nokogiri::XML::parse(File.read(alto_path))
        end

        def write_files
          pages = doc.css('//Page')
          pages.each_with_index do |page, i|
            filename = "#{File.basename(page_filenames[i], File.extname(page_filenames[i]))}.xml"
            File.write(output_path(filename), xml_structure(page).to_xml)
          end
          true
        end

        private

        def output_path(filename)
          File.join(File.dirname(alto_path), filename)
        end

        def xml_structure(page)
          Nokogiri::XML::Builder.new do |xml|
            xml.alto(namespaces) do
              xml.parent << ocr_processing_nodes
              xml.parent << style_nodes
              xml.parent << page
            end
          end
        end

        def namespaces
          @namespaces ||= { 'xsi:schemaLocation': 'http://www.loc.gov/standards/alto/ns-v3# http://www.loc.gov/alto/v3/alto-3-1.xsd' }.merge(doc.collect_namespaces)
        end

        def style_nodes
          @style_nodes ||= doc.css('//Styles')
        end

        def ocr_processing_nodes
          @ocr_processing_nodes ||= doc.css('//OCRProcessing')
        end

        def page_filenames
          @page_filenames ||= doc.css('//sourceImageInformation').children.select(&:element?).map(&:text)
        end
      end
    end
  end
end
