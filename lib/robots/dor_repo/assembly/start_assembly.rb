# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      # Kicks off assembly by making sure the item is open
      class StartAssembly < Robots::DorRepo::Assembly::Base
        def initialize
          super('assemblyWF', 'start-assembly')
        end

        def perform_work
          raise 'Assembly has been started with an object that is not open' unless object_client.version.status.open?
        end
      end
    end
  end
end
