
module Accession

  class ProvenanceMetadata < LyberCore::Robots::Robot

    def initialize(opts = {})
      super('accessionWF', 'provenance-metadata', opts)
    end

    def process_item(work_item)
      obj = Dor::Item.find(work_item.druid)
      obj.build_provenanceMetadata_datastream('accessionWF','DOR Common Accessioning completed')
    end

  end

end


