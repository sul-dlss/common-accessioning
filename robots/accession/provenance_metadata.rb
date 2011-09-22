
module Accession

  class ProvenanceMetadata < LyberCore::Robots::Robot

    def initialize(opts = {})
      super('accessionWF', 'provenance-metadata', opts)
    end

    def process_item(work_item)
      obj = Dor::Item.load_instance(work_item.druid)
      obj.build_provenanceMetadata_datastream('accessionWF','Common Accessioning')
    end

  end

end


