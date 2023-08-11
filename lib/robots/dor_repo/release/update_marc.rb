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
          logger.debug "update_marc handing off to dor-services-app job for update to #{druid}"
          object_client.update_marc_record

          # Since the actual update work is completed by dor-services-app in a job,
          # workflow logging (marking step completed or failed) is done there.
          LyberCore::ReturnState.new(status: :noop, note: 'Initiated update_marc_record API call.')
        end
      end
    end
  end
end
