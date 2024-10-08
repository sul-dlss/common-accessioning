# frozen_string_literal: true

module Dor
  module TextExtraction
    # Send an entry to the dor-services-app event log
    class DorEventLogger
      # @param [Logger] an instance of a Ruby Logger (for debug etc logging)
      def initialize(logger:)
        Dor::Services::Client.configure(logger:, url: Settings.dor_services.url, token: Settings.dor_services.token)
      end

      # Publish to the SDR event service with processing information
      def create_event(druid:, type:, data:)
        Dor::Services::Client.object(druid).events.create(type:, data:)
      end
    end
  end
end
