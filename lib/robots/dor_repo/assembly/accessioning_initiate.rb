# frozen_string_literal: true

module Robots
  module DorRepo
    module Assembly
      # Closes the version, which starts accessionWF.
      class AccessioningInitiate < Robots::DorRepo::Assembly::Base
        def initialize
          super('assemblyWF', 'accessioning-initiate')
        end

        def perform_work
          logger.info("Initiate accessioning for #{druid}")
          close_version
          true
        end

        private

        def close_version
          object_client.version.close(lane_id:)
        end
      end
    end
  end
end
