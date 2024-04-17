# frozen_string_literal: true

module Robots
  module DorRepo
    module Caption
      # End the captioning process by closing the object version
      class EndCaption < LyberCore::Robot
        def initialize
          super('captionWF', 'end-caption')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          # close version
          true
        end
      end
    end
  end
end
