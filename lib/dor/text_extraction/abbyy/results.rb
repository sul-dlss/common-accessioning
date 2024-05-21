# frozen_string_literal: true

module Dor
  module TextExtraction
    module Abbyy
      # Parses .xml.result.xml file that gets created when Abbyy sees a XMLTICKET
      class Results
        attr_reader :result_path, :druid, :run_index

        # Naming convention for result XML files:
        # ab123cd4567.xml.result.xml
        # ab123cd4567.xml.0001.result.xml
        RESULT_FILE_PATTERN = /(?<druid>\w+)\.xml(?:\.(?<run_index>\d+))?\.result\.xml/

        def initialize(result_path:)
          @result_path = result_path
          druid, run_index = RESULT_FILE_PATTERN.match(File.basename(result_path)).captures
          @druid = druid
          @run_index = (run_index || 0).to_i
        end

        def success?
          xml_contents.at('@IsFailed').text == 'false'
        end

        def failure_messages
          errors = xml_contents.xpath("//Message[@Type='Error']//Text")
          errors&.map(&:text)
        end

        def output_docs
          output_docs = xml_contents.xpath('//OutputDocuments')
          {}.tap do |structural|
            output_docs.each do |doc|
              doc_type = doc.xpath('@ExportFormat').text.downcase
              structural[doc_type] = File.join(doc.xpath('@OutputLocation').text, doc.xpath('FileName').text)
            end
          end
        end

        def alto_doc
          output_docs['alto']
        end

        private

        def xml_contents
          @xml_contents ||= Nokogiri::XML(File.read(result_path))
        end
      end
    end
  end
end
