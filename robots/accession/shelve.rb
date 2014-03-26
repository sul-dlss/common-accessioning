module Accession

  class Shelve < LyberCore::Robots::Robot

    def initialize
      super('dor', 'accessionWF', 'shelve')
    end

    def perform(druid)
      obj = Dor::Item.find(druid)
      obj.shelve
    end

  end
end
