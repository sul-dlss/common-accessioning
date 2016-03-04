
module Robots
  module DorRepo
    module Accession

      class ProvenanceMetadata < Robots::DorRepo::Accession::Base
        def initialize
          super('dor', 'accessionWF', 'provenance-metadata')
        end

        def perform(druid)
          obj = Dor::Item.find(druid)
          obj.build_provenanceMetadata_datastream('accessionWF', 'DOR Common Accessioning completed')
        end

      end

    end
  end
end
