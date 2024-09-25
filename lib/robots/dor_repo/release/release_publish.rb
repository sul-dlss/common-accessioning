# frozen_string_literal: true

# Robot class to run under multiplexing infrastructure
module Robots
  module DorRepo
    module Release
      # Sends release tags to Purl Fetcher
      class ReleasePublish < LyberCore::Robot
        def initialize
          super('releaseWF', 'release-publish')
        end

        # `perform` is the main entry point for the robot. This is where
        # all of the robot's work is done.
        #
        # @param [String] druid -- the Druid identifier for the object to process
        def perform_work
          logger.debug "release-publish working on #{druid}"

          return LyberCore::ReturnState.new(status: :skipped, note: 'item is dark so it cannot be published') if cocina_object.dro? && cocina_object.access.view == 'dark'

          index = targets_for(release: true)
          delete = targets_for(release: false)

          PurlFetcher::Client.configure(url: Settings.purl_fetcher.url, token: Settings.purl_fetcher.token)
          PurlFetcher::Client::ReleaseTags.release(druid:, index:, delete:)
        end

        def release_tags
          @release_tags ||= object_client.release_tags.list(public: true) # we only want the latest public release tags
        end

        def targets_for(release:)
          release_tags.select { |tag| tag.release == release }.map(&:to)
        end
      end
    end
  end
end
