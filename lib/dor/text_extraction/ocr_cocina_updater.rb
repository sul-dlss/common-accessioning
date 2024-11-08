# frozen_string_literal: true

module Dor
  module TextExtraction
    # Update Cocina structural metadata with OCR files
    class OcrCocinaUpdater < CocinaUpdater
      def update
        rename_document_pdf
        super
      end

      private

      # Rename the PDF that was generated for an Item of type document
      # TODO: maybe xml_ticket_create.rb should be adjusted to create it this way?
      def rename_document_pdf
        file = find_workspace_file("#{bare_druid}.pdf")
        return unless file && document?

        new_filename = content_dir + "#{bare_druid}-generated.pdf"
        file.rename(new_filename)

        add_file_to_new_resource(new_filename)
      end

      # set the use attribute based on the mimetype (only XML and PDF OCR files will have a use attribute set to 'transcription')
      def use(object_file)
        %w[application/pdf application/xml].include?(object_file.mimetype) ? 'transcription' : nil
      end

      def resource_label(path)
        extension = path.extname
        if extension == '.txt'
          'Plain text OCR (uncorrected)'
        elsif extension == '.pdf' && document?
          'PDF (with automated OCR)'
        elsif extension == '.pdf'
          'Full PDF'
        else
          raise "Unable to determine resource label for #{path}"
        end
      end
    end
  end
end
