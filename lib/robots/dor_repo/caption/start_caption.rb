# frozen_string_literal: true

module Robots
  module DorRepo
    module Caption
      # Start the captioning process by opening the object version
      class StartCaption < LyberCore::Robot
        def initialize
          super('captionWF', 'start-caption')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          # open version if possible
          true
        end
      end
    end
  end
end
