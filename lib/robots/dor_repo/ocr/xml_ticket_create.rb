# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # Create the XML ticket for ABBYY and write to the file system
      class XmlTicketCreate < LyberCore::Robot
        def initialize
          super('ocrWF', 'xml-ticket-create')
        end

        # available from LyberCore::Robot: druid, bare_druid, object_workflow, object_client, cocina_object, logger
        def perform_work
          workflow_context = workflow.context
          filepaths = Dor::TextExtraction::Ocr.new(cocina_object:, workflow_context:).filenames_to_ocr
          Dor::TextExtraction::Abbyy::Ticket.new(filepaths:, druid:, ocr_languages: workflow_context['ocrLanguages']).write_xml
        end
      end
    end
  end
end
