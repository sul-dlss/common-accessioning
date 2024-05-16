# frozen_string_literal: true

module Robots
  module DorRepo
    module Ocr
      # Fetch files in need of OCR from Preservation
      class FetchFiles < LyberCore::Robot
        def initialize
          super('ocrWF', 'fetch-files')
        end

        def perform_work
          copy_files
        end

        private

        def copy_files
          ocrable_filenames.each do |filename|
            path = abbyy_path(filename)
            path.parent.mkpath unless path.parent.directory?
            path.open('wb') do |file_writer|
              preservation_client.objects.content(druid:,
                                                  filepath: filename,
                                                  on_data: proc { |data, _count| file_writer.write(data) })
            end
          end
        end

        def bare_druid
          druid.split(':').last
        end

        def abbyy_path(filename)
          # NOTE: if files of type "file" were allowed here we would have to
          # deal with file hierarchy (subdirectories)
          Pathname.new(File.join(Settings.sdr.abbyy_ticket_path, bare_druid, filename))
        end

        def ocrable_filenames
          @ocrable_filenames ||= ocr.required? && ocr.possible? ? ocr.filenames_to_ocr : []
        end

        def ocr
          @ocr = Dor::TextExtraction::Ocr.new(cocina_object:, workflow_context: workflow.context)
        end

        def preservation_client
          @preservation_client ||= Preservation::Client.configure(url: Settings.preservation_catalog.url, token: Settings.preservation_catalog.token)
        end
      end
    end
  end
end
