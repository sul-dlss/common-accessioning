# frozen_string_literal: true

module Dor
  module TextExtraction
    module Abbyy
      # Build Abbyy tickets for processing
      class Ticket
        attr_reader :filepaths, :druid

        def initialize(filepaths:, druid:)
          @filepaths = filepaths
          @druid = druid
        end

        def write_xml
          File.write(file_path, xml)
        end

        private

        def file_path
          File.join(Settings.sdr.abbyy_ticket_path, "#{druid}.xml")
        end

        def image_output
          [pdfa_output, alto_output, text_output].join("\n")
        end

        def pdf_files?
          File.extname(filepaths.first).strip.downcase[1..] == 'pdf'
        end

        def output_file_path
          File.join(Settings.sdr.abbyy_output_path, druid).encode(xml: :text)
        end

        def alto_output
          "<ExportFormat OutputFileFormat='ALTO' OutputFlowType='SharedFolder' FormatVersion='3_1' CoordinatesParticularity='Words' WriteWordConfidence='true'>
            <OutputLocation>#{output_file_path}</OutputLocation>
            <FileExistsAction>Overwrite</FileExistsAction>
            <NamingRule>#{druid}.&lt;Ext&gt;</NamingRule>
          </ExportFormat>"
        end

        def text_output
          "<ExportFormat OutputFileFormat='Text' OutputFlowType='SharedFolder' EncodingType='UTF8'>
            <OutputLocation>#{output_file_path}</OutputLocation>
            <FileExistsAction>Overwrite</FileExistsAction>
            <NamingRule>#{druid}.&lt;Ext&gt;</NamingRule>
          </ExportFormat>"
        end

        def pdfa_output
          "<ExportFormat OutputFileFormat='PDFA' OutputFlowType='SharedFolder'
                        PdfAComplianceMode='PDFAM_PdfA_2u' PdfVersion='Version17'
                        Scenario='MaxQuality' UseImprovedCompression='true' MRCMode='Normal'
                        PdfUACompatible='true'>
            <OutputLocation>#{output_file_path}</OutputLocation>
            <FileExistsAction>Overwrite</FileExistsAction>
            <NamingRule>#{druid}.&lt;Ext&gt;</NamingRule>
          </ExportFormat>"
        end

        def input_filepaths_field
          filepaths.map { |filename| "<InputFile Name=#{filename.encode(xml: :attr)}/>" }.join("\n")
        end

        def xml
          "<?xml version='1.0'?>
          <XmlTicket>
            <ExportParams XMLResultPublishingMethod='XMLResultToFolder'>
              #{pdf_files? ? pdfa_output : image_output}
              <XMLResultLocation>#{Settings.sdr.abbyy_result_path.encode(xml: :text)}</XMLResultLocation>
            </ExportParams>
            #{input_filepaths_field}
          </XmlTicket>"
        end
      end
    end
  end
end
