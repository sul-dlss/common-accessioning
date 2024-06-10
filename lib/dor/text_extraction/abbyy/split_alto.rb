# frozen_string_literal: true

module Dor
  module TextExtraction
    module Abbyy
      # Split ALTO file into page files
      class SplitAlto
        attr_reader :alto_path, :doc

        def initialize(alto_path:)
          @alto_path = alto_path
          @doc = Nokogiri::XML(File.read(alto_path))
        end

        def write_files
          split_to_files.each do |filename, xml_content|
            File.write(output_path(filename), xml_content)
          end
        end

        private

        def output_path(filename)
          File.join(File.dirname(alto_path), filename)
        end

        # rubocop:disable Metrics/AbcSize
        def xml_structure(page)
          namespaces = { 'xsi:schemaLocation': 'http://www.loc.gov/standards/alto/ns-v3# http://www.loc.gov/alto/v3/alto-3-1.xsd' }.merge(doc.collect_namespaces)
          Nokogiri::XML::Builder.new do |xml|
            xml.alto(namespaces) do
              doc.css('//MeasurementUnit').each { |node| xml.parent << node.dup }
              doc.css('//OCRProcessing').each { |node| xml.parent << node.dup }
              doc.css('//Styles').each { |node| xml.parent << node.dup }
              xml.parent << page
            end
          end
        end

        def page_filenames
          @page_filenames ||= doc.css('//sourceImageInformation').children.select(&:element?).map(&:text)
        end
        # rubocop:enable Metrics/AbcSize

        def split_to_files
          pages = doc.css('//Page')
          {}.tap do |file_hash|
            pages.each_with_index do |page, i|
              filename = "#{File.basename(page_filenames[i], File.extname(page_filenames[i]))}.xml"
              file_hash[filename] = xml_structure(page).to_xml
            end
          end
        end
      end
    end
  end
end
