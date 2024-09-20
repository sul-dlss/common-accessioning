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
      # This method will retry fetching the file up to `max_tries` times.
      # @param [String] filename the filename to fetch
      # @param [Pathname] path the path to write the file to (leave off if sending to cloud)
      # @param [String] bucket the S3 bucket to write the file to (leave off if sending to disk)
      # @param [Symbol] method (could be :file or :cloud), default to :file
      # @param [Integer] max_tries the number of times to retry fetching the file
      # @return [Boolean] true if the file was fetched and written, false otherwise
      # rubocop:disable Metrics/MethodLength
      def write_file_with_retries(filename:, max_tries: 3, path: nil, bucket: nil, method: :file)
        tries = 0
        written = false
        begin
          written = if method == :file
                      fetch_and_write_file_to_disk(filename:, path:)
                    else
                      fetch_and_send_file_to_s3(filename:, bucket:)
                    end
        rescue Faraday::ResourceNotFound
          tries += 1
          logger.warn("received NotFoundError from Preservation try ##{tries}")

          sleep(2**tries)

          retry unless tries > max_tries

          context = { druid:, filename:, path: path.to_s, bucket:, max_tries: }
          logger.error("Exceeded max_tries attempting to fetch file: #{context}")
          Honeybadger.notify('Exceeded max_tries attempting to fetch file', context:)
        end

        written
      end
      # rubocop:enable Metrics/MethodLength

      # fetch a file from preservation and send to cloud endpoint
      # TODO: implement this method for AWS S3, it will be used for the speech-to-text workflow
      def fetch_and_send_file_to_s3(filename:, bucket:)
        logger.info("fetching #{filename} for #{druid} and sending to #{bucket}")
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
