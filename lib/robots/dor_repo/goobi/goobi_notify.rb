# frozen_string_literal: true

module Robots
  module DorRepo
    module Goobi
      # Robot class to run under multiplexing infrastructure
      class GoobiNotify < LyberCore::Robot
        def initialize
          super('goobiWF', 'goobi-notify')
        end

        # `perform` is the main entry point for the robot. This is where
        # all of the robot's work is done.
        #
        # @param [String] druid -- the Druid identifier for the object to process
        def perform_work
          object_client.notify_goobi
        end
      end
    end
  end
end
