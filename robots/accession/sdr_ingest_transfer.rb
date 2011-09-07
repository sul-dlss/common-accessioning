
module Accession

  class SdrIngestTransfer < LyberCore::Robots::Robot

    def initialize(opts = {})
      super('accessionWF', 'sdr-ingest-transfer', opts)
    end

    def process_item(work_item)
      obj = Dor::Item.load_instance(work_item.druid)
      obj.sdr_ingest_transfer(work_item.identity_metadata.agreementId)
    end


  end

end


