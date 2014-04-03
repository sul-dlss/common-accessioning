module Robots
  module DorRepo
    module Accession

      class Shelve
        include LyberCore::Robot

        def initialize
          super('dor', 'accessionWF', 'shelve')
        end

        def perform(druid)
          obj = Dor::Item.find(druid)
          obj.shelve
        end

      end

    end
  end
end
