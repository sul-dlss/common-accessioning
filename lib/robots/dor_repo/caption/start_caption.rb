# frozen_string_literal: true

module Robots
  module DorRepo
    module Caption
      # Start the captioning process by opening the object version
      class StartCaption < LyberCore::Robot
        def initialize
          super('captionWF', 'start-caption')
        end

        def perform_work
          return LyberCore::ReturnState.new(status: :noop, note: 'Object is already open.') if object_client.version.status.open? # object is currently open

          object_client.version.open
        end
      end
    end
  end
end
