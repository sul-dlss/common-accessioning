
module Accession

  class SdrIngestTransfer < LyberCore::Robots::Robot

    def initialize
      super('dor', 'accessionWF', 'sdr-ingest-transfer')
    end

    def perform(druid)
      obj = Dor::Item.find(druid)
      obj.sdr_ingest_transfer("")
    end


  end

end


