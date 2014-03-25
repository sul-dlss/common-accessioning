
module Accession

  class ProvenanceMetadata < LyberCore::Robots::Robot

    def initialize
      super('dor', 'accessionWF', 'provenance-metadata')
    end

    def process_item
      obj = Dor::Item.find(@druid)
      obj.build_provenanceMetadata_datastream('accessionWF','DOR Common Accessioning completed')
    end

  end

end


