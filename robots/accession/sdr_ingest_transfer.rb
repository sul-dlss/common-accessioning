
module Robots
  module DorRepo
    module Accession

      class SdrIngestTransfer < Robots::DorRepo::Accession::Base
        def initialize
          super('dor', 'accessionWF', 'sdr-ingest-transfer')
        end

        def perform(druid)
          obj = Dor.find(druid)
          obj.sdr_ingest_transfer('')
        end
      end

    end
  end
end
