# frozen_string_literal: true

module Dor
  module TextExtraction
    # Fetch files from preservation to make them available for text extraction (ocr or speech-to-text)
    class FileFetcher
      attr_reader :druid, :logger

      def initialize(druid:, logger: nil)
        @druid = druid
        @logger = logger || Logger.new($stdout)
      end

      # Fetch an item's file from Preservation and write it to disk. Since
      # we've observed inconsistency in QA and Stage with the NFS volumes
      # where files are written, we need to recheck.
      # This method will retry fetching the file up to `max_tries` times.
      # @param [String] filename the filename to fetch
      # @param [Object] location to write the file (could be a Pathname object, a string representing a local path, or an S3Object for AWS)
      # @param [Integer] max_tries the number of times to retry fetching the file
      # @return [Boolean] true if the file was fetched and written, false otherwise
      # rubocop:disable Metrics/MethodLength
      def write_file_with_retries(filename:, location:, max_tries: 3)
        tries = 0
        written = false
        begin
          written = if location.is_a?(String) || location.is_a?(Pathname)
                      fetch_and_write_file_to_disk(filename:, path: Pathname.new(location))
                    elsif location.is_a?(Aws::S3::Object)
                      fetch_and_send_file_to_s3(filename:, s3_object: location)
                    else
                      raise "Unknown location type: #{location.class}"
                    end
        rescue Faraday::ResourceNotFound
          tries += 1
          logger.warn("received NotFoundError from Preservation try ##{tries}")

          sleep(2**tries)

          retry unless tries > max_tries

          context = { druid:, filename:, max_tries: }.tap do |ctx|
            ctx[:path] = location.to_s if location.is_a?(Pathname) || location.is_a?(String)
            ctx[:bucket] = location.bucket_name if location.is_a?(Aws::S3::Object)
          end

          logger.error("Exceeded max_tries attempting to fetch file: #{context}")
          Honeybadger.notify('Exceeded max_tries attempting to fetch file', context:)
        end

        written
      end
      # rubocop:enable Metrics/MethodLength

      private

      # fetch a file from preservation and send to cloud endpoint
      def fetch_and_send_file_to_s3(filename:, s3_object:)
        logger.info("fetching #{filename} for #{druid} and sending to #{s3_object.bucket_name}")
        s3_object.upload_stream do |upload_stream|
          preservation_client.objects.content(
            druid:,
            filepath: filename,
            on_data: proc { |data, _count| upload_stream.write(data) }
          )
        end

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

      def preservation_client
        @preservation_client ||= Preservation::Client.configure(url: Settings.preservation_catalog.url, token: Settings.preservation_catalog.token)
      end
    end
  end
end
