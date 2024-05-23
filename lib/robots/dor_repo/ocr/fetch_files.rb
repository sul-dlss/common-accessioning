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
            raise "Unable to find #{druid}" unless write_file_with_retries(druid:, filename:, path:, max_tries: 3)
          end
        end

        def abbyy_path(filename)
          # NOTE: if files of type "file" were allowed here we would have to
          # deal with file hierarchy (subdirectories)
          Pathname.new(File.join(abbyy_input_path, filename))
        end

        def abbyy_input_path
          @abbyy_input_path ||= Dor::TextExtraction::Ocr.new(cocina_object:, workflow_context: workflow.context).abbyy_input_path
        end

        def ocrable_filenames
          @ocrable_filenames ||= ocr.required? && ocr.possible? ? ocr.filenames_to_ocr : []
        end

        def ocr
          @ocr = Dor::TextExtraction::Ocr.new(cocina_object:, workflow_context: workflow.context)
        end

        # Fetch an item's file from Preservation and write it to disk. Since
        # we've observed inconsistency in QA and Stage with the NFS volumes
        # where files are written we recheck.
        # rubocop:disable Metrics/MethodLength
        def write_file_with_retries(druid:, filename:, path:, max_tries:)
          tries = 0
          written = false
          begin
            written = fetch_file(druid:, filename:, path:)
          rescue Faraday::ResourceNotFound
            tries += 1
            logger.warn("received NotFoundError from Preservation try ##{tries}")

            sleep(2**tries)

            retry unless tries > max_tries
          end

          written
        end
        # rubocop:enable Metrics/MethodLength

        def fetch_file(druid:, filename:, path:)
          path.open('wb') do |file_writer|
            logger.info("fetching #{filename} for #{druid} and saving to #{path}")
            preservation_client.objects.content(
              druid:,
              filepath: filename,
              on_data: proc { |data, _count| file_writer.write(data) }
            )
          end

          true
        end

        def preservation_client
          @preservation_client ||= Preservation::Client.configure(url: Settings.preservation_catalog.url, token: Settings.preservation_catalog.token)
        end
      end
    end
  end
end
