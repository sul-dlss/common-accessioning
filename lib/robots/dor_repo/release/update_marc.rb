# frozen_string_literal: true

module Robots
  module DorRepo
    module Release
      class UpdateMarc < LyberCore::Robot
        def initialize
          super('releaseWF', 'update-marc')
        end

        # `perform` is the main entry point for the robot. This is where
        # all of the robot's work is done.
        #
        # @param [String] druid -- the Druid identifier for the object to process
        def perform_work
          logger.debug "update_marc working on #{druid}"
          object_client.update_marc_record
        end
      end
    end
  end
end
