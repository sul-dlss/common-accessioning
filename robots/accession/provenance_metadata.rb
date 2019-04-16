# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession

      class ProvenanceMetadata < Robots::DorRepo::Base
        def initialize
          super('dor', 'accessionWF', 'provenance-metadata')
        end

        def perform(druid)
          obj = Dor.find(druid)
          obj.build_provenanceMetadata_datastream('accessionWF', 'DOR Common Accessioning completed')
        end
      end
    end
  end
end
