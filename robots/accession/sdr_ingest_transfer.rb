# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession

      class SdrIngestTransfer < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'sdr-ingest-transfer')
        end

        def perform(druid)
          obj = Dor.find(druid)
          Dor::SdrIngestService.transfer(obj)
        end
      end
    end
  end
end
