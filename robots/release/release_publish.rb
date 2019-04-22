# frozen_string_literal: true

# Robot class to run under multiplexing infrastructure
module Robots
  module DorRepo
    module Release
      # Sends updated metadata to PURL. Specifically stuff in identityMetadata
      class ReleasePublish < Robots::DorRepo::Base
        def initialize
          super('dor', 'releaseWF', 'release-publish', check_queued_status: true) # init LyberCore::Robot
        end

        # `perform` is the main entry point for the robot. This is where
        # all of the robot's work is done.
        #
        # @param [String] druid -- the Druid identifier for the object to process
        def perform(druid)
          LyberCore::Log.debug "release-publish working on #{druid}"
          item = Dor::Release::Item.new druid: druid
          PublishMetadataService.publish(item.object)
        end
      end
    end
  end
end
