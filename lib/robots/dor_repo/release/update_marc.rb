# frozen_string_literal: true

module Robots
  module DorRepo
    module Release
      class UpdateMarc < Robots::DorRepo::Base
        def initialize
          super('dor', 'releaseWF', 'update-marc', check_queued_status: true) # init LyberCore::Robot
        end

        # `perform` is the main entry point for the robot. This is where
        # all of the robot's work is done.
        #
        # @param [String] druid -- the Druid identifier for the object to process
        def perform(druid)
          LyberCore::Log.debug "update_marc working on #{druid}"
          with_retries(max_tries: Settings.release.max_tries,
                       base_sleep_seconds: Settings.release.base_sleep_seconds,
                       max_sleep_seconds: Settings.release.max_sleep_seconds) do |_attempt|
            Dor::Services::Client.object(druid).update_marc_record
          end
        end
      end
    end
  end
end
