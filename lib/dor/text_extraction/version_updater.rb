# frozen_string_literal: true

module Dor
  module TextExtraction
    # Open a version, wrapped in retries
    class VersionUpdater
      attr_reader :druid, :object_client, :description, :max_tries

      def initialize(druid:, object_client:, description:, max_tries:)
        @druid = druid
        @object_client = object_client
        @description = description
        @max_tries = max_tries
      end

      def self.open(druid:, object_client:, description:, max_tries: 3)
        new(druid:, object_client:, description:, max_tries:).open_object
      end

      # rubocop:disable Metrics/MethodLength
      def open_object
        # don't do it if already open
        return if object_client.version.status.open?

        tries = 0
        begin
          object_client.version.open(description:)
        rescue Dor::Services::Client::UnexpectedResponse => e
          tries += 1
          sleep(2**tries)

          raise e unless tries < max_tries

          Honeybadger.notify('[NOTE] Problem opening object version', context: { description:, druid:, tries:, error: e })
          retry
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
