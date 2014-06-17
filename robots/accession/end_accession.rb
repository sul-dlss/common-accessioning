
module Robots
  module DorRepo
    module Accession

      class EndAccession
        include LyberCore::Robot

        def initialize
          super('dor', 'accessionWF', 'end-accession')
        end

        def perform(druid)
          obj = Dor::Item.find(druid)
          obj.clear_diff_cache
          obj.initiate_workflow 'disseminationWF'
        end
      end

    end
  end
end
