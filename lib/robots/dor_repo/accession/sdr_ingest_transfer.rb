# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      class SdrIngestTransfer < Robots::DorRepo::Base
        def initialize
          super('accessionWF', 'sdr-ingest-transfer')
        end

        def perform(druid)
          Dor::Services::Client.object(druid).preserve(lane_id: lane_id(druid))
          LyberCore::Robot::ReturnState.new(status: :noop, note: 'Initiated preserve API call.')
        end
      end
    end
  end
end
