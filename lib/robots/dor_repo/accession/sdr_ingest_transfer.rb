# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      class SdrIngestTransfer < LyberCore::Robot
        def initialize
          super('accessionWF', 'sdr-ingest-transfer')
        end

        def perform_work
          object_client.preserve(lane_id:)
          LyberCore::ReturnState.new(status: :noop, note: 'Initiated preserve API call.')
        end
      end
    end
  end
end
