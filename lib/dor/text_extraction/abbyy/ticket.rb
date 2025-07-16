# frozen_string_literal: true

module Dor
  module TextExtraction
    module Abbyy
      # Build Abbyy tickets for processing
      class Ticket
        attr_reader :filepaths, :ocr_languages, :bare_druid

        def initialize(filepaths:, druid:, ocr_languages: [])
          @filepaths = filepaths
          @bare_druid = druid.delete_prefix('druid:')
          @ocr_languages = ocr_languages
        end

        def write_xml
          File.write(file_path, xml)
        end

        def file_path
          File.join(Settings.sdr.abbyy.local_ticket_path, "#{bare_druid}.xml")
        end

        private

        def image_output
          [pdfa_output, alto_output, text_output].join("\n")
        end

        def pdf_files?
          File.extname(filepaths.first).strip.downcase[1..] == 'pdf'
        end

        def output_file_path
          File.join(Settings.sdr.abbyy.remote_output_path, bare_druid).encode(xml: :text)
        end

        def language_xml
          return '' if ocr_languages.blank?

          language_tags = ocr_languages.map { |lang| "<Language>#{lang}</Language>" }.join("\n")
          "<RecognitionParams RecognitionQuality='Balanced' RecognitionMode='FullPage' UsePullXTextAndRecognizeRest='false' LanguageDetectMode='Always'>
          <TextType>Normal</TextType>
          #{language_tags}
          </RecognitionParams>"
        end

        def alto_output
          "<ExportFormat OutputFileFormat='ALTO' WriteOriginalImageCoordinates='true' OutputFlowType='SharedFolder' FormatVersion='3_1' CoordinatesParticularity='Words' WriteWordConfidence='true'>
            <OutputLocation>#{output_file_path}</OutputLocation>
            <FileExistsAction>Overwrite</FileExistsAction>
            <NamingRule>#{bare_druid}.&lt;Ext&gt;</NamingRule>
          </ExportFormat>"
        end

        def text_output
          "<ExportFormat OutputFileFormat='Text' OutputFlowType='SharedFolder' EncodingType='UTF8'>
            <OutputLocation>#{output_file_path}</OutputLocation>
            <FileExistsAction>Overwrite</FileExistsAction>
            <NamingRule>#{bare_druid}.&lt;Ext&gt;</NamingRule>
          </ExportFormat>"
        end

        def pdfa_output
          "<ExportFormat OutputFileFormat='PDFA' OutputFlowType='SharedFolder'
                        PdfAComplianceMode='PDFAM_PdfA_2u' PdfVersion='Version17'
                        Scenario='MaxQuality' UseImprovedCompression='true' MRCMode='Normal'
                        PdfUACompatible='true'>
            <OutputLocation>#{output_file_path}</OutputLocation>
            <FileExistsAction>Overwrite</FileExistsAction>
            <NamingRule>#{bare_druid}.&lt;Ext&gt;</NamingRule>
          </ExportFormat>"
        end

        def image_processing_profile
          "<ImageProcessingProfile>
            <ImageOperation Operation='Rotate' RotationType='Automatic'/>
          </ImageProcessingProfile>"
        end

        def input_filepaths_field
          # windows filepath since Abbyy service runs on a Windows machine
          filepaths.map do |filename|
            filename = filename.gsub('/', '\\')
            path = "#{bare_druid}\\#{filename}"
            "<InputFile Name=#{path.encode(xml: :attr)}/>"
          end.join("\n")
        end

        def xml
          "<?xml version='1.0'?>
          <XmlTicket>
            #{image_processing_profile}
            #{language_xml}
            <ExportParams XMLResultPublishingMethod='XMLResultToFolder'>
              #{pdf_files? ? pdfa_output : image_output}
              <XMLResultLocation>#{Settings.sdr.abbyy.remote_result_path.encode(xml: :text)}</XMLResultLocation>
            </ExportParams>
            #{input_filepaths_field}
          </XmlTicket>"
        end
      end
    end
  end
end
