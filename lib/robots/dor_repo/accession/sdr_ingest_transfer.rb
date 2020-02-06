# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      class SdrIngestTransfer < Robots::DorRepo::Base
        def initialize
          super('accessionWF', 'sdr-ingest-transfer')
        end

        def perform(druid)
          Dor::Services::Client.object(druid).preserve
        end
      end
    end
  end
end
