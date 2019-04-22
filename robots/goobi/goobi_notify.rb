# frozen_string_literal: true

module Robots
  module DorRepo
    module Goobi
      # Robot class to run under multiplexing infrastructure
      class GoobiNotify < Robots::DorRepo::Base
        def initialize
          super('dor', 'goobiWF', 'goobi-notify', check_queued_status: true) # init LyberCore::Robot
        end

        # `perform` is the main entry point for the robot. This is where
        # all of the robot's work is done.
        #
        # @param [String] druid -- the Druid identifier for the object to process
        def perform(druid)
          LyberCore::Log.debug "goobi-notify working on #{druid}"

          with_retries(max_tries: Dor::Config.goobi.max_tries, base_sleep_seconds: Dor::Config.goobi.base_sleep_seconds, max_sleep_seconds: Dor::Config.goobi.max_sleep_seconds) do |_attempt|
            Dor::Services::Client.object(druid).notify_goobi
          end
        end
      end
    end
  end
end
