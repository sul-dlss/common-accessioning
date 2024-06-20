# frozen_string_literal: true

module Dor
  module TextExtraction
    module Abbyy
      # Split ALTO file into page files
      class SplitAlto
        attr_reader :alto_path, :ocr_processing_nodes, :style_nodes, :page_filename_nodes

        def initialize(alto_path:)
          @alto_path = alto_path
        end

        def write_files
          fetch_common_nodes
          write_page_files
          true
        end

        private

        def output_path(filename)
          File.join(File.dirname(alto_path), filename)
        end

        # NOTE: we avoid using Nokogiri XML Builder to build the XML structure to reduce memory usage
        def xml_structure(page)
          "<?xml version=\"1.0\"?>\n<alto #{namespaces}>\n#{ocr_processing_nodes}\n#{style_nodes}\n#{page}\n</alto>\n"
        end

        # NOTE: do not use Nokogiri to load and parse the XML in memory at once as it is memory intensive
        # first pass through the XML to get the common nodes
        def fetch_common_nodes
          Nokogiri::XML::Reader(File.open(alto_path)).each do |node|
            @style_nodes = node.outer_xml if node?(node, 'Styles')
            @ocr_processing_nodes = node.outer_xml if node?(node, 'OCRProcessing')
            @page_filename_nodes = node.outer_xml if node?(node, 'sourceImageInformation')
          end
        end

        # second pass through the XML to get the page nodes and write them to separate files
        def write_page_files
          i = 0
          Nokogiri::XML::Reader(File.open(alto_path)).each do |node|
            next unless node?(node, 'Page')

            filename = "#{File.basename(page_filenames[i], File.extname(page_filenames[i]))}.xml"
            File.write(output_path(filename), xml_structure(node.outer_xml))
            i += 1
          end
        end

        def node?(node, name)
          node.name == name && node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
        end

        def namespaces
          'xmlns="http://www.loc.gov/standards/alto/ns-v3#" ' \
            'xmlns:xlink="http://www.w3.org/1999/xlink" ' \
            'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' \
            'xsi:schemaLocation="http://www.loc.gov/standards/alto/ns-v3# http://www.loc.gov/alto/v3/alto-3-1.xsd"'
        end

        def page_filenames
          @page_filenames ||= Nokogiri::XML(page_filename_nodes).css('//sourceImageInformation').children.select(&:element?).map(&:text)
        end
      end
    end
  end
end
