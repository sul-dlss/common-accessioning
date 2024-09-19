# frozen_string_literal: true

module Dor
  module TextExtraction
    # Fetch files from preservation to make them available for text extraction (ocr or speech-to-text)
    class FileFetcher
      attr_reader :druid, :logger

      def initialize(druid:, logger:)
        @druid = druid
        @logger = logger
      end

      # Fetch an item's file from Preservation and write it to disk. Since
      # we've observed inconsistency in QA and Stage with the NFS volumes
      # where files are written, we need to recheck.
      # @param [String] filename the filename to fetch
      # @param [Pathname] path the path to write the file to (leave off if you don't want to write to disk)
      # @param [String] cloud_endpoint the cloud endpoint to send the file to (leave off if you don't want to send to cloud)
      # @param [Integer] max_tries the number of times to retry fetching the file
      # rubocop:disable Metrics/MethodLength
      def write_file_with_retries(filename:, max_tries: 3, path: nil, cloud_endpoint: nil)
        tries = 0
        written = false
        begin
          if path
            written = fetch_and_write_file_to_disk(filename:, path:)
          elsif cloud_endpoint
            written = fetch_and_send_file_to_s3(filename:, cloud_endpoint:)
          end
        rescue Faraday::ResourceNotFound
          tries += 1
          logger.warn("received NotFoundError from Preservation try ##{tries}")

          sleep(2**tries)

          retry unless tries > max_tries

          context = { druid:, filename:, path: path.to_s, cloud_endpoint:, max_tries: }
          logger.error("Exceeded max_tries attempting to fetch file: #{context}")
          Honeybadger.notify('Exceeded max_tries attempting to fetch file', context:)
        end

        written
      end
      # rubocop:enable Metrics/MethodLength

      # fetch a file from preservation and send to cloud endpoint
      # TODO: implement this method for AWS S3, it will be used for the speech-to-text workflow
      def fetch_and_send_file_to_s3(filename:, cloud_endpoint:)
        logger.info("fetching #{filename} for #{druid} and sending to #{cloud_endpoint}")
        preservation_client.objects.content(
          druid:,
          filepath: filename,
          on_data: proc { |_data, _count| } # actually send the file to the cloud endpoint
        )

        true # NOTE: return false on failure
      end

      # fetch a file from perservation and write to disk
      def fetch_and_write_file_to_disk(filename:, path:)
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

      private

      def preservation_client
        @preservation_client ||= Preservation::Client.configure(url: Settings.preservation_catalog.url, token: Settings.preservation_catalog.token)
      end
    end
  end
end
