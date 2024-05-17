# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # Create the XML ticket for ABBYY and write to the file system
      class XmlTicketCreate < LyberCore::Robot
        def initialize
          super('ocrWF', 'xml-ticket-create')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          # generate and write the XML ticket to the file system
        end
      end
    end
  end
end
