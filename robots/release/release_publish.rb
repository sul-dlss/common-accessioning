# frozen_string_literal: true

# Robot class to run under multiplexing infrastructure
module Robots
  module DorRepo
    module Release
      class ReleasePublish < Robots::DorRepo::Base
        # Build off the base robot implementation which implements
        # features common to all robots
        include LyberCore::Robot

        def initialize
          super('dor', Dor::Config.release.workflow_name, 'release-publish', check_queued_status: true) # init LyberCore::Robot
        end

        # `perform` is the main entry point for the robot. This is where
        # all of the robot's work is done.
        #
        # @param [String] druid -- the Druid identifier for the object to process
        def perform(druid)
          LyberCore::Log.debug "release-publish working on #{druid}"
          item = Dor::Release::Item.new druid: druid
          item.object.publish_metadata # if item.republish_needed?  # assuming you have a "republish_needed?" method on dor-services, which we don't have currently, so just do a publish for now
        end
      end
    end
  end
end
