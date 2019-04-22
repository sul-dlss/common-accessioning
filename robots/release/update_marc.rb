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
          item = Dor::Release::Item.new druid: druid
          item.update_marc_record # this makes a web-service call for dor-services app
        end
      end
    end
  end
end
