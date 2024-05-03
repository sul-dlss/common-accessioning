# frozen_string_literal: true

# Robot class to run under multiplexing infrastructure
module Robots
  module DorRepo
    module Release
      # Sends updated metadata to PURL. Specifically stuff in identityMetadata
      class ReleasePublish < LyberCore::Robot
        def initialize
          super('releaseWF', 'release-publish')

          PurlFetcher::Client.configure(url: Settings.purl_fetcher.url,
                                        token: Settings.purl_fetcher.token,
                                        logger:)
        end

        # `perform` is the main entry point for the robot. This is where
        # all of the robot's work is done.
        #
        # @param [String] druid -- the Druid identifier for the object to process
        def perform_work
          logger.debug "release-publish working on #{druid}"
          # This is an async result and it will have a callback.
          object_client.publish(workflow: 'releaseWF')
          PurlFetcher::Client::ReleaseTags.release(druid:, index: [], delete: [])

          LyberCore::ReturnState.new(status: :noop, note: 'Initiated publish API call.')
        end
      end
    end
  end
end
