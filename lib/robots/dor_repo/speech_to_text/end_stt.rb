# frozen_string_literal: true

module Robots
  module DorRepo
    module SpeechToText
      # End the speech to text process by closing the object version
      class EndStt < LyberCore::Robot
        def initialize
          super('speechToTextWF', 'end-stt')
        end

        def perform_work
          object_client.version.close
        end
      end
    end
  end
end
