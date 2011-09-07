
module Accession

  class Cleanup < LyberCore::Robots::Robot

    def initialize(opts = {})
      super('accessionWF', 'cleanup', opts)
    end

    def process_item(work_item)
      obj = Dor::Item.load_instance(work_item.druid)
      obj.sdr_ingest_transfercleanup()
    end


  end

end


