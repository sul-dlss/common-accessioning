
module Accession

  class SdrIngestTransfer
    include  LyberCore::Robot

    def initialize
      super('dor', 'accessionWF', 'sdr-ingest-transfer')
    end

    def perform(druid)
      obj = Dor::Item.find(druid)
      obj.sdr_ingest_transfer("")
    end


  end

end


