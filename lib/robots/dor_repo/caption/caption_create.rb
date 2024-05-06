# frozen_string_literal: true

module Robots
  module DorRepo
    module Caption
      # Call the captioning service to generate captions
      class CaptionCreate < LyberCore::Robot
        def initialize
          super('captionWF', 'caption-create')
        end

        # available from LyberCore::Robot: druid, bare_druid, workflow_service, object_client, cocina_object, logger
        def perform_work
          # do the caption creation by calling out to Whisper
          true
        end
      end
    end
  end
end
