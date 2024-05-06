# frozen_string_literal: true

module Robots
  module DorRepo
    module Caption
      # End the captioning process by closing the object version
      class EndCaption < LyberCore::Robot
        def initialize
          super('captionWF', 'end-caption')
        end

        def perform_work
          object_client.version.close
          true
        end
      end
    end
  end
end
