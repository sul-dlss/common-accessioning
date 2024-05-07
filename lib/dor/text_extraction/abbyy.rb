# frozen_string_literal: true

module Dor
  module TextExtraction
    # Build Abbyy tickets for processing
    class Abbyy
      def initialize(filepaths:, druid:)
        @filepaths = filepaths
        @druid = druid
      end

      def abbyy_ticket_filepath
        File.join(Settings.sdr.abbyy_ticket_path, "#{@druid}.xml")
      end

      def image_abbyy
        [pdfa_output, alto_output, text_output].join("\n")
      end

      def pdf_files?
        File.extname(@filepaths.first).strip.downcase[1..] == 'pdf'
      end

      def alto_output
        "<ExportFormat OutputFileFormat='ALTO' OutputFlowType='SharedFolder' FormatVersion='3_1' CoordinatesParticularity='Words' WriteWordConfidence='true'>
          <OutputLocation>#{Settings.sdr.abbyy_output_path.encode(xml: :text)}</OutputLocation>
          <FileExistsAction>Overwrite</FileExistsAction>
          <NamingRule>&lt;FileName&gt;.&lt;Ext&gt;</NamingRule>
        </ExportFormat>"
      end

      def text_output
        "<ExportFormat OutputFileFormat='Text' OutputFlowType='SharedFolder' EncodingType='UTF8'>
          <OutputLocation>#{Settings.sdr.abbyy_output_path.encode(xml: :text)}</OutputLocation>
          <FileExistsAction>Overwrite</FileExistsAction>
          <NamingRule>&lt;FileName&gt;.&lt;Ext&gt;</NamingRule>
        </ExportFormat>"
      end

      def pdfa_output
        "<ExportFormat OutputFileFormat='PDFA' OutputFlowType='SharedFolder'
                       PdfAComplianceMode='PDFAM_PdfA_2u' PdfVersion='Version17'
                       Scenario='MaxQuality' UseImprovedCompression='true' MRCMode='Normal'
                       PdfUACompatible='true'>
          <OutputLocation>#{Settings.sdr.abbyy_output_path.encode(xml: :text)}</OutputLocation>
          <FileExistsAction>Overwrite</FileExistsAction>
          <NamingRule>&lt;FileName&gt;.&lt;Ext&gt;</NamingRule>
        </ExportFormat>"
      end

      def input_filepaths_field
        @filepaths.map { |filename| "<InputFile Name=#{filename.encode(xml: :attr)}/>" }.join("\n")
      end

      def xml_ticket
        xml = "<?xml version='1.0'?>
        <XmlTicket>
          <ExportParams DocumentSeparationMethod='OneFilePerImage' XMLResultPublishingMethod='XMLResultToFolder'>
            #{pdf_files? ? pdfa_output : image_abbyy}
            <XMLResultLocation>#{Settings.sdr.abbyy_result_path.encode(xml: :text)}</XMLResultLocation>
          </ExportParams>
          #{input_filepaths_field}
        </XmlTicket>"
        File.write(abbyy_ticket_filepath, xml)
      end
    end
  end
end
