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
          raise 'Object is already open' if object_client.version.status.open?

          object_client.version.open(description: 'Start caption workflow')
        end
      end
    end
  end
end
